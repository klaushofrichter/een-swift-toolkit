import Testing
import Foundation
@testable import EENApiToolkit

@Suite("QueryParamEncoding Tests")
struct QueryParamEncodingTests {

    @Test("QueryItemBuilder adds string values")
    func addsStringValues() {
        var b = QueryItemBuilder()
        b.add("name", "test")
        b.add("missing", nil as String?)
        #expect(b.items.count == 1)
        #expect(b.items[0].name == "name")
        #expect(b.items[0].value == "test")
    }

    @Test("QueryItemBuilder adds pagination")
    func addsPagination() {
        var b = QueryItemBuilder()
        b.addPagination(pageSize: 20, pageToken: "abc123")
        #expect(b.items.count == 2)
        #expect(b.items[0].name == "pageSize")
        #expect(b.items[0].value == "20")
        #expect(b.items[1].name == "pageToken")
        #expect(b.items[1].value == "abc123")
    }

    @Test("QueryItemBuilder adds __in filter")
    func addsInFilter() {
        var b = QueryItemBuilder()
        b.addIn("status", ["online", "offline"])
        #expect(b.items.count == 1)
        #expect(b.items[0].name == "status__in")
        #expect(b.items[0].value == "online,offline")
    }

    @Test("QueryItemBuilder skips empty arrays")
    func skipsEmptyArrays() {
        var b = QueryItemBuilder()
        b.addIn("status", [])
        b.addIn("status", nil)
        b.addContains("tags", [])
        #expect(b.items.isEmpty)
    }

    @Test("QueryItemBuilder adds __gte and __lte")
    func addsGteLte() {
        var b = QueryItemBuilder()
        b.addGte("timestamp", "2024-01-01T00:00:00.000+00:00")
        b.addLte("timestamp", "2024-12-31T23:59:59.000+00:00")
        #expect(b.items.count == 2)
        #expect(b.items[0].name == "timestamp__gte")
        #expect(b.items[1].name == "timestamp__lte")
    }

    @Test("QueryItemBuilder adds __ne filter")
    func addsNeFilter() {
        var b = QueryItemBuilder()
        b.addNe("status", "offline")
        #expect(b.items[0].name == "status__ne")
        #expect(b.items[0].value == "offline")
    }

    @Test("ListCamerasParams encodes correctly")
    func listCamerasParamsEncoding() {
        var params = ListCamerasParams(pageSize: 10)
        params.statusIn = [.online, .streaming]
        params.tagsContains = ["entrance"]
        params.q = "lobby"

        let items = params.toQueryItems()
        let dict = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })

        #expect(dict["pageSize"] == "10")
        #expect(dict["status__in"] == "online,streaming")
        #expect(dict["tags__contains"] == "entrance")
        #expect(dict["q"] == "lobby")
    }

    @Test("ListEventsParams encodes required fields")
    func listEventsParamsEncoding() {
        let params = ListEventsParams(
            actor: "camera:abc123",
            typeIn: ["een.motionDetectionEvent.v1"],
            startTimestampGte: "2024-01-01T00:00:00.000Z"
        )
        let items = params.toQueryItems()
        let dict = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })

        #expect(dict["actor"] == "camera:abc123")
        #expect(dict["type__in"] == "een.motionDetectionEvent.v1")
        #expect(dict["startTimestamp__gte"] == "2024-01-01T00:00:00.000Z")
    }
}
