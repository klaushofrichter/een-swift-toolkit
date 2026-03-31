import Foundation

/// Options for configuring an SSE connection.
public struct SSEConnectionOptions: Sendable {
    public let onEvent: @Sendable (SSEEvent) -> Void
    public let onError: (@Sendable (Error) -> Void)?
    public let onStatusChange: (@Sendable (SSEConnectionStatus) -> Void)?

    public init(
        onEvent: @escaping @Sendable (SSEEvent) -> Void,
        onError: (@Sendable (Error) -> Void)? = nil,
        onStatusChange: (@Sendable (SSEConnectionStatus) -> Void)? = nil
    ) {
        self.onEvent = onEvent
        self.onError = onError
        self.onStatusChange = onStatusChange
    }
}

/// A connection to an SSE event stream. Call `close()` to disconnect.
public final class SSEConnection: NSObject, @unchecked Sendable {
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private let options: SSEConnectionOptions
    private var buffer = ""
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    public private(set) var status: SSEConnectionStatus = .connecting {
        didSet {
            if oldValue != status {
                options.onStatusChange?(status)
            }
        }
    }

    init(url: String, token: String, options: SSEConnectionOptions) {
        self.options = options
        super.init()

        guard let sseUrl = URL(string: url) else {
            self.status = .error
            options.onError?(EENError(code: .validationError, message: "Invalid SSE URL: \(url)"))
            return
        }

        var request = URLRequest(url: sseUrl)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = .infinity

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = .infinity
        config.timeoutIntervalForResource = .infinity
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.session = session

        let task = session.dataTask(with: request)
        self.task = task

        EENDebug.log("SSE connecting to \(url)")
        updateStatus(.connecting)
        task.resume()
    }

    /// Close the SSE connection.
    public func close() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        updateStatus(.disconnected)
        EENDebug.log("SSE connection closed")
    }

    private func updateStatus(_ newStatus: SSEConnectionStatus) {
        lock.lock()
        defer { lock.unlock() }
        status = newStatus
    }

    private func processBuffer() {
        // SSE protocol: events separated by blank lines
        while let range = buffer.range(of: "\n\n") {
            let eventBlock = String(buffer[buffer.startIndex..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])

            processEventBlock(eventBlock)
        }
    }

    private func processEventBlock(_ block: String) {
        var dataLines: [String] = []

        for line in block.components(separatedBy: "\n") {
            if line.hasPrefix("data:") {
                let value = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                dataLines.append(value)
            }
            // Ignore id:, event:, retry: lines for now
        }

        guard !dataLines.isEmpty else { return }

        let jsonString = dataLines.joined(separator: "\n")
        guard let jsonData = jsonString.data(using: .utf8) else { return }

        do {
            let event = try decoder.decode(SSEEvent.self, from: jsonData)
            options.onEvent(event)
        } catch {
            EENDebug.log("SSE parse error: \(error.localizedDescription)")
        }
    }
}

extension SSEConnection: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            if (200..<300).contains(httpResponse.statusCode) {
                updateStatus(.connected)
                EENDebug.log("SSE connected (status \(httpResponse.statusCode))")
            } else {
                updateStatus(.error)
                options.onError?(EENError(code: .apiError, message: "SSE connection failed", status: httpResponse.statusCode))
            }
        }
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        lock.lock()
        buffer += chunk
        processBuffer()
        lock.unlock()
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            if (error as NSError).code == NSURLErrorCancelled {
                updateStatus(.disconnected)
            } else {
                updateStatus(.error)
                options.onError?(EENError(code: .networkError, message: "SSE connection lost: \(error.localizedDescription)"))
            }
        } else {
            updateStatus(.disconnected)
        }
    }
}
