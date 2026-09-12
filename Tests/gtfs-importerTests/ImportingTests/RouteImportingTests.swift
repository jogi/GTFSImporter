import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct RouteImportingTests {
    @Test("Missing and empty route fields receive defaults", arguments: [false, true])
    func defaults(emptyColumns: Bool) throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            let csv =
                emptyColumns
                ? "route_id,route_type,route_color,route_text_color,route_sort_order,continuous_pickup,continuous_drop_off\nX,3,,,,,"
                : "route_id,route_type\nX,3"
            try ImportTestSupport.receive(Route.self, csv: csv, in: db)
            let route = try #require(try Route.fetchOne(db, key: "X"))
            #expect(route.color == "FFFFFF")
            #expect(route.textColor == "000000")
            #expect(route.sortOrder == 0)
            #expect(route.continuousPickup == .notContinuous)
            #expect(route.continuousDropoff == .notContinuous)
        }
    }

    @Test("Explicit route values survive defaulting")
    func explicitValues() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                Route.self,
                csv: """
                    route_id,route_type,route_color,route_text_color,route_sort_order,continuous_pickup,continuous_drop_off
                    X,3,112233,AABBCC,7,2,3
                    """, in: db)
            let route = try #require(try Route.fetchOne(db, key: "X"))
            #expect(route.color == "112233")
            #expect(route.textColor == "AABBCC")
            #expect(route.sortOrder == 7)
            #expect(route.continuousPickup == .phoneAgencyToArrange)
            #expect(route.continuousDropoff == .coordinateWithDriver)
        }
    }

    @Test("Route receiver skips invalid and duplicate rows without losing valid routes")
    func rejectedRows() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                Route.self,
                csv: """
                    route_id,route_type,route_short_name
                    FIRST,3,Original
                    FIRST,3,Duplicate
                    BAD,999,Invalid
                    LAST,0,Later
                    """, in: db)
            let routes = try Route.fetchAll(db, sql: "SELECT * FROM routes WHERE route_id != 'R' ORDER BY route_id")
            #expect(routes.map(\.identifier) == ["FIRST", "LAST"])
            #expect(routes.map(\.shortName) == ["Original", "Later"])
            #expect(routes.map(\.type) == [.bus, .tram])
        }
    }
}
