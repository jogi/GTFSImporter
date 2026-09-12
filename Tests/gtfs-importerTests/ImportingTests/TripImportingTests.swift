import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct TripImportingTests {
    @Test(
        "Trip accessibility defaults only when absent",
        arguments: [
            ("", "", 0, 0),
            (",wheelchair_accessible,bikes_allowed", ",,", 0, 0),
            (",wheelchair_accessible,bikes_allowed", ",1,2", 1, 2),
        ])
    func accessibility(header: String, fields: String, wheelchair: Int, bikes: Int) throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                Trip.self,
                csv:
                    "trip_id,route_id,service_id\(header)\nX,R,S\(fields)", in: db)
            let trip = try #require(try Trip.fetchOne(db, key: "X"))
            #expect(trip.wheelchairAccessible?.rawValue == wheelchair)
            #expect(trip.bikesAllowed?.rawValue == bikes)
        }
    }
}
