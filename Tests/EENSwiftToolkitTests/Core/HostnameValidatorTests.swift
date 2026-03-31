import Testing
@testable import EENSwiftToolkit

@Suite("HostnameValidator Tests")
struct HostnameValidatorTests {

    @Test("Allows valid EEN hostnames")
    func allowsValidHostnames() {
        #expect(HostnameValidator.isAllowed("c001.eagleeyenetworks.com"))
        #expect(HostnameValidator.isAllowed("api.eagleeyenetworks.com"))
        #expect(HostnameValidator.isAllowed("eagleeyenetworks.com"))
        #expect(HostnameValidator.isAllowed("c001.een.cloud"))
        #expect(HostnameValidator.isAllowed("api.een.cloud"))
        #expect(HostnameValidator.isAllowed("een.cloud"))
    }

    @Test("Rejects invalid hostnames")
    func rejectsInvalidHostnames() {
        #expect(!HostnameValidator.isAllowed("evil.com"))
        #expect(!HostnameValidator.isAllowed("eagleeyenetworks.com.evil.com"))
        #expect(!HostnameValidator.isAllowed("noteagleeyenetworks.com"))
        #expect(!HostnameValidator.isAllowed(""))
        #expect(!HostnameValidator.isAllowed("localhost"))
        #expect(!HostnameValidator.isAllowed("192.168.1.1"))
    }

    @Test("Case insensitive matching")
    func caseInsensitive() {
        #expect(HostnameValidator.isAllowed("C001.EagleEyeNetworks.COM"))
        #expect(HostnameValidator.isAllowed("API.EEN.CLOUD"))
    }

    @Test("Validates base URLs")
    func validatesBaseUrls() throws {
        let url = try HostnameValidator.validateBaseUrl("https://c001.eagleeyenetworks.com")
        #expect(url == "https://c001.eagleeyenetworks.com")
    }

    @Test("Rejects invalid base URLs")
    func rejectsInvalidBaseUrls() {
        #expect(throws: EENError.self) {
            try HostnameValidator.validateBaseUrl("https://evil.com")
        }
        #expect(throws: EENError.self) {
            try HostnameValidator.validateBaseUrl("not-a-url")
        }
    }
}
