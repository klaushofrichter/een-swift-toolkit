import Foundation
import EENApiToolkit

struct BoundingBox: Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct CameraEvent: Identifiable, Equatable {
    let id: UUID
    let eventId: String?
    let timestamp: Date
    let type: String
    let actorId: String
    let description: String
    let raw: String
    let boundingBoxes: [BoundingBox]

    init(type: String, actorId: String, description: String, raw: String = "", timestamp: Date = Date(), eventId: String? = nil, boundingBoxes: [BoundingBox] = []) {
        self.id = UUID()
        self.eventId = eventId
        self.timestamp = timestamp
        self.type = type
        self.actorId = actorId
        self.description = description
        self.raw = raw
        self.boundingBoxes = boundingBoxes
    }

    /// Extract bounding boxes from event data items.
    /// The EEN API returns `een.objectDetection.v1` data items with a
    /// `boundingBox` array of `[x1, y1, x2, y2]` in normalized 0-1 coordinates.
    static func extractBoundingBoxes(from data: [EventData]) -> [BoundingBox] {
        var boxes: [BoundingBox] = []
        for eventData in data {
            guard eventData.type == "een.objectDetection.v1",
                  let props = eventData.additionalProperties,
                  let bbox = props["boundingBox"],
                  case .array(let coords) = bbox,
                  coords.count == 4 else { continue }
            let values = coords.compactMap { doubleValue($0) }
            guard values.count == 4 else { continue }
            let (x1, y1, x2, y2) = (values[0], values[1], values[2], values[3])
            boxes.append(BoundingBox(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
        }
        return boxes
    }

    private static func doubleValue(_ value: AnyCodable) -> Double? {
        switch value {
        case .double(let v): return v
        case .int(let v): return Double(v)
        default: return nil
        }
    }

    nonisolated static func == (lhs: CameraEvent, rhs: CameraEvent) -> Bool {
        lhs.id == rhs.id
    }

    var typeEmoji: String {
        switch type.lowercased() {
        case let t where t.contains("motion"):
            return "🏃"
        case let t where t.contains("online"):
            return "🟢"
        case let t where t.contains("offline"):
            return "🔴"
        case let t where t.contains("tamper"):
            return "⚠️"
        case let t where t.contains("recording"):
            return "⏺️"
        default:
            return "📋"
        }
    }
}
