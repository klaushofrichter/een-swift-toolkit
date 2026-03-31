import Testing
@testable import EENSwiftToolkit

@Suite("InMemoryTokenStorage Tests")
struct TokenStorageTests {

    @Test("Save and load values")
    func saveAndLoad() throws {
        let storage = InMemoryTokenStorage()
        try storage.save(key: "token", value: "abc123")
        let loaded = try storage.load(key: "token")
        #expect(loaded == "abc123")
    }

    @Test("Load returns nil for missing keys")
    func loadMissing() throws {
        let storage = InMemoryTokenStorage()
        let loaded = try storage.load(key: "nonexistent")
        #expect(loaded == nil)
    }

    @Test("Delete removes values")
    func deleteValue() throws {
        let storage = InMemoryTokenStorage()
        try storage.save(key: "token", value: "abc123")
        try storage.delete(key: "token")
        let loaded = try storage.load(key: "token")
        #expect(loaded == nil)
    }

    @Test("Overwrite existing values")
    func overwrite() throws {
        let storage = InMemoryTokenStorage()
        try storage.save(key: "token", value: "old")
        try storage.save(key: "token", value: "new")
        let loaded = try storage.load(key: "token")
        #expect(loaded == "new")
    }
}
