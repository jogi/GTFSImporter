import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct StopTimeImportingTests {
    @Test(
        "Stop-time defaults preserve explicit values",
        arguments: [
            ("", "", [0, 0, 1, 1, 1]),
            (",pickup_type,drop_off_type,continuous_pickup,continuous_drop_off,timepoint", ",,,,,", [0, 0, 1, 1, 1]),
            (
                ",pickup_type,drop_off_type,continuous_pickup,continuous_drop_off,timepoint", ",2,3,0,2,0",
                [2, 3, 0, 2, 0]
            ),
        ])
    func defaults(header: String, fields: String, expected: [Int]) throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                StopTime.self,
                csv:
                    "trip_id,stop_id,stop_sequence,arrival_time,departure_time\(header)\nT,A,1,25:30:00,25:31:00\(fields)",
                in: db)
            #expect(try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times") == "25:30:00")
            let stop = try #require(try StopTime.fetchOne(db))
            #expect(
                [
                    stop.pickupType?.rawValue, stop.dropoffType?.rawValue,
                    stop.continuousPickup?.rawValue, stop.continuousDropoff?.rawValue,
                    stop.timepoint?.rawValue,
                ] == expected.map(Optional.some))
            #expect(stop.isLastStop == false)
            #expect(try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times") == "25:30:00")
            #expect(try String.fetchOne(db, sql: "SELECT departure_time FROM stop_times") == "25:31:00")
        }
    }

    @Test(
        "Bad time rows are skipped without losing later valid rows",
        arguments: ["garbage", "12:30", "12:60:00", "-1:00:00"])
    func invalidRows(time: String) throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                StopTime.self,
                csv: """
                    trip_id,stop_id,stop_sequence,arrival_time,departure_time
                    T,A,1,08:00:00,08:00:00
                    T,B,2,\(time),08:10:00
                    T,C,3,08:20:00,08:20:00
                    """, in: db)
            #expect(try Int.fetchAll(db, sql: "SELECT stop_sequence FROM stop_times ORDER BY stop_sequence") == [1, 3])
        }
    }

    @Test("Last-stop marking uses each trip's maximum sequence and resets stale flags")
    func lastStops() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('U','R','S')")
            try ImportTestSupport.receive(
                StopTime.self,
                csv: """
                    trip_id,stop_id,stop_sequence,arrival_time,departure_time
                    T,C,20,08:20:00,08:20:00
                    U,A,9,09:00:00,09:00:00
                    T,A,2,08:00:00,08:00:00
                    T,B,7,08:10:00,08:10:00
                    """, in: db)
            try db.execute(sql: "UPDATE stop_times SET is_laststop = 1")
            try StopTime.updateLastStop(in: db)
            #expect(
                try String.fetchAll(
                    db,
                    sql: "SELECT trip_id || ':' || stop_sequence FROM stop_times WHERE is_laststop = 1 ORDER BY trip_id"
                ) == ["T:20", "U:9"])
        }
    }
}
