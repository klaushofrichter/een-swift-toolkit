import Testing
import Foundation
@testable import EENSwiftToolkit

@Suite("Camera Model Tests")
struct CameraModelTests {

    @Test("Decodes camera with string status")
    func decodesCameraWithStringStatus() throws {
        let json = """
        {
            "id": "cam1",
            "name": "Front Door",
            "accountId": "acc1",
            "status": "online",
            "tags": ["entrance", "outdoor"]
        }
        """.data(using: .utf8)!

        let camera = try JSONDecoder().decode(Camera.self, from: json)
        #expect(camera.id == "cam1")
        #expect(camera.name == "Front Door")
        #expect(camera.status?.effectiveStatus == .online)
        #expect(camera.tags == ["entrance", "outdoor"])
    }

    @Test("Decodes camera with object status")
    func decodesCameraWithObjectStatus() throws {
        let json = """
        {
            "id": "cam2",
            "name": "Lobby",
            "accountId": "acc1",
            "status": {"connectionStatus": "offline"}
        }
        """.data(using: .utf8)!

        let camera = try JSONDecoder().decode(Camera.self, from: json)
        #expect(camera.status?.effectiveStatus == .offline)
    }

    @Test("Decodes camera with device info")
    func decodesCameraWithDeviceInfo() throws {
        let json = """
        {
            "id": "cam3",
            "name": "Parking",
            "accountId": "acc1",
            "deviceInfo": {
                "make": "Axis",
                "model": "P3245-V",
                "directToCloud": true
            },
            "devicePosition": {
                "latitude": 37.7749,
                "longitude": -122.4194
            }
        }
        """.data(using: .utf8)!

        let camera = try JSONDecoder().decode(Camera.self, from: json)
        #expect(camera.deviceInfo?.make == "Axis")
        #expect(camera.deviceInfo?.directToCloud == true)
        #expect(camera.devicePosition?.latitude == 37.7749)
    }
}
