import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct StopImportingTests {
    @Test(
        "Stop location type and wheelchair boarding default when absent or empty",
        arguments: [
            ("", "", Stop.LocationType.stop, Stop.WheelchairBoarding.noInformation),
            (",location_type,wheelchair_boarding", ",,", .stop, .noInformation),
            (",location_type,wheelchair_boarding", ",1,2", .station, .notAccessible),
        ])
    func defaults(
        header: String,
        fields: String,
        locationType: Stop.LocationType,
        wheelchairBoarding: Stop.WheelchairBoarding
    ) throws {
        let queue = try DatabaseQueue()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try Stop.createTable(db: db)
            try ImportTestSupport.receive(
                Stop.self,
                csv: "stop_id,stop_name,stop_lat,stop_lon\(header)\nS1,Central,37.33,-121.89\(fields)",
                in: db)
            let stop = try #require(try Stop.fetchOne(db, key: "S1"))
            #expect(stop.locationType == locationType)
            #expect(stop.wheelchairBording == wheelchairBoarding)
        }
    }

    @Test("Stop receiver skips invalid and duplicate rows without losing valid stops")
    func rejectedRows() throws {
        let queue = try DatabaseQueue()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try Stop.createTable(db: db)
            try ImportTestSupport.receive(
                Stop.self,
                csv: """
                    stop_id,stop_name,stop_lat,stop_lon,location_type,wheelchair_boarding
                    FIRST,Original,37.33,-121.89,,
                    FIRST,Duplicate,37.33,-121.89,0,1
                    BAD_WHEELCHAIR,Invalid Wheelchair,37.33,-121.89,0,99
                    BAD_LOCATION,Invalid Location,37.33,-121.89,99,0
                    LAST,Later,37.34,-121.90,1,1
                    """,
                in: db)
            let stops = try Stop.fetchAll(db, sql: "SELECT * FROM stops ORDER BY rowid")
            #expect(stops.map(\.identifier) == ["FIRST", "LAST"])
            #expect(stops.map(\.name) == ["Original", "Later"])
            #expect(stops.map(\.locationType) == [.stop, .station])
            #expect(stops.map(\.wheelchairBording) == [.noInformation, .partiallyAccessible])
        }
    }
}
