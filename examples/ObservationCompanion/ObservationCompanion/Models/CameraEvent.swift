import Foundation

struct CameraEvent: Identifiable, Equatable {
    let id: UUID
    let eventId: String?
    let timestamp: Date
    let type: String
    let actorId: String
    let description: String
    let raw: String

    init(type: String, actorId: String, description: String, raw: String = "", timestamp: Date = Date(), eventId: String? = nil) {
        self.id = UUID()
        self.eventId = eventId
        self.timestamp = timestamp
        self.type = type
        self.actorId = actorId
        self.description = description
        self.raw = raw
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
