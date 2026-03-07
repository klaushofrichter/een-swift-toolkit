import SwiftUI
import EENApiToolkit

struct RecordedImageView: View {
    let toolkit: EENToolkit
    @Binding var cameraId: String?
    @Binding var selectedDate: Date
    @State private var previewImage: UIImage?
    @State private var mainImage: UIImage?
    @State private var previewTimestamp: String?
    @State private var mainTimestamp: String?
    @State private var nextToken: String?
    @State private var prevToken: String?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var mainImageUnavailable = false
    @State private var previewImageUnavailable = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Time picker
                HStack {
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .accessibilityIdentifier("TimePicker")

                    Button("Go") {
                        Task { await fetchImages(timestamp: selectedDate) }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("GoButton")

                    Button("Now") {
                        selectedDate = Date().addingTimeInterval(-60)
                        Task { await fetchImages(timestamp: selectedDate) }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                // Navigation
                HStack {
                    Button {
                        Task { await fetchWithToken(prevToken, direction: "prev") }
                    } label: {
                        Label("Previous", systemImage: "chevron.left")
                    }
                    .disabled(prevToken == nil)
                    .accessibilityIdentifier("PrevButton")

                    Spacer()

                    Button {
                        Task { await fetchWithToken(nextToken, direction: "next") }
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .disabled(nextToken == nil)
                    .accessibilityIdentifier("NextButton")
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView("Loading recorded images...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if cameraId == nil {
                    Text("Select a camera to view recorded images")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }

                // Preview image
                if let previewImage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview")
                            .font(.headline)
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .accessibilityIdentifier("PreviewImage")
                        if let previewTimestamp {
                            Text(previewTimestamp)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                } else if previewImageUnavailable {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview")
                            .font(.headline)
                        Text("Image not available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // Main image
                if let mainImage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Main (Full Resolution)")
                            .font(.headline)
                        Image(uiImage: mainImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .accessibilityIdentifier("MainImage")
                        if let mainTimestamp {
                            Text(mainTimestamp)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                } else if mainImageUnavailable {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Main (Full Resolution)")
                            .font(.headline)
                        Text("Image not available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
        .onChange(of: cameraId) { _ in
            clearImages()
        }
    }

    private func fetchImages(timestamp: Date) async {
        guard let cameraId else { return }
        isLoading = true
        errorMessage = nil
        clearImages()

        let ts = formatTimestamp(timestamp)

        // Fetch preview
        do {
            var params = GetRecordedImageParams()
            params.type = .preview
            params.timestampGte = ts
            let result = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: params)
            if let img = UIImage(data: result.imageData) {
                previewImage = img
                previewTimestamp = result.timestamp
                nextToken = result.nextToken
                prevToken = result.prevToken
            } else {
                previewImageUnavailable = true
            }
        } catch {
            previewImageUnavailable = true
        }

        // Fetch main quality
        do {
            var params = GetRecordedImageParams()
            params.type = .main
            params.timestampGte = ts
            let result = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: params)
            if let img = UIImage(data: result.imageData) {
                mainImage = img
                mainTimestamp = result.timestamp
            } else {
                mainImageUnavailable = true
            }
        } catch {
            mainImageUnavailable = true
        }

        isLoading = false
    }

    private func fetchWithToken(_ token: String?, direction: String) async {
        guard let cameraId, let token else { return }
        isLoading = true
        errorMessage = nil

        do {
            var params = GetRecordedImageParams()
            params.type = .preview
            params.pageToken = token
            let result = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: params)
            if let img = UIImage(data: result.imageData) {
                previewImage = img
                previewTimestamp = result.timestamp
                nextToken = result.nextToken
                prevToken = result.prevToken
            }

            // Also fetch main quality at the same timestamp
            mainImage = nil
            mainTimestamp = nil
            mainImageUnavailable = false
            if let ts = result.timestamp {
                var mainParams = GetRecordedImageParams()
                mainParams.type = .main
                mainParams.timestampGte = ts
                do {
                    let mainResult = try await toolkit.media.getRecordedImage(deviceId: cameraId, params: mainParams)
                    if let img = UIImage(data: mainResult.imageData) {
                        mainImage = img
                        mainTimestamp = mainResult.timestamp
                    } else {
                        mainImageUnavailable = true
                    }
                } catch {
                    mainImageUnavailable = true
                }
            } else {
                mainImageUnavailable = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func clearImages() {
        previewImage = nil
        mainImage = nil
        previewTimestamp = nil
        mainTimestamp = nil
        nextToken = nil
        prevToken = nil
        errorMessage = nil
        mainImageUnavailable = false
        previewImageUnavailable = false
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(identifier: "UTC")
        // EEN API requires +00:00 format, not Z
        return formatter.string(from: date).replacingOccurrences(of: "Z", with: "+00:00")
    }
}
