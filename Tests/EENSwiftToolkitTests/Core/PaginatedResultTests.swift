import Testing
import Foundation
@testable import EENSwiftToolkit

@Suite("PaginatedResult Tests")
struct PaginatedResultTests {

    @Test("Decodes paginated user response")
    func decodesPaginatedUsers() throws {
        let json = """
        {
            "results": [
                {"id": "user1", "email": "a@b.com", "firstName": "John", "lastName": "Doe"},
                {"id": "user2", "email": "c@d.com", "firstName": "Jane", "lastName": "Smith"}
            ],
            "nextPageToken": "token123",
            "totalSize": 42
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(PaginatedResult<User>.self, from: json)
        #expect(result.results.count == 2)
        #expect(result.results[0].id == "user1")
        #expect(result.results[1].email == "c@d.com")
        #expect(result.nextPageToken == "token123")
        #expect(result.totalSize == 42)
        #expect(result.prevPageToken == nil)
    }

    @Test("Decodes empty results")
    func decodesEmptyResults() throws {
        let json = """
        {"results": []}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(PaginatedResult<User>.self, from: json)
        #expect(result.results.isEmpty)
        #expect(result.nextPageToken == nil)
    }
}
