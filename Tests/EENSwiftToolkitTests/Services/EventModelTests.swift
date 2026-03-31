import Testing
import Foundation
@testable import EENSwiftToolkit

@Suite("Event Model Tests")
struct EventModelTests {

    @Test("Decodes event with data")
    func decodesEvent() throws {
        let json = """
        {
            "id": "evt1",
            "startTimestamp": "2024-01-15T10:30:00.000+00:00",
            "endTimestamp": null,
            "span": false,
            "accountId": "acc1",
            "actorId": "cam1",
            "actorAccountId": "acc1",
            "actorType": "camera",
            "creatorId": "bridge1",
            "type": "een.motionDetectionEvent.v1",
            "dataSchemas": ["een.motionDetection.v1"],
            "data": [
                {"type": "een.motionDetection.v1", "creatorId": "bridge1", "confidence": 0.95}
            ]
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(Event.self, from: json)
        #expect(event.id == "evt1")
        #expect(event.actorType == .camera)
        #expect(event.span == false)
        #expect(event.data.count == 1)
        #expect(event.data[0].type == "een.motionDetection.v1")
    }

    @Test("Decodes event type")
    func decodesEventType() throws {
        let json = """
        {"type": "een.motionDetectionEvent.v1", "name": "Motion Detection", "description": "Detected motion"}
        """.data(using: .utf8)!

        let eventType = try JSONDecoder().decode(EventType.self, from: json)
        #expect(eventType.type == "een.motionDetectionEvent.v1")
        #expect(eventType.name == "Motion Detection")
    }

    @Test("Decodes SSE event")
    func decodesSSEEvent() throws {
        let json = """
        {
            "id": "sse1",
            "startTimestamp": "2024-01-15T10:30:00.000+00:00",
            "actorId": "cam1",
            "type": "een.motionDetectionEvent.v1"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(SSEEvent.self, from: json)
        #expect(event.id == "sse1")
        #expect(event.actorId == "cam1")
    }
}
