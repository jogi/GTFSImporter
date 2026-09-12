import GRDB
import Testing

@testable import gtfs_importer

struct StopTimeInterpolatorTests {
    struct Scenario: Sendable, CustomTestStringConvertible {
        let name: String
        let latitudes: [Double]
        let input: [String]
        let expected: [String]
        var testDescription: String { name }
    }

    @Test(
        "Interpolation respects distance and surrounding anchors",
        arguments: [
            Scenario(
                name: "unequal distances", latitudes: [0, 1, 4], input: ["08:00:00", "", "08:20:00"],
                expected: ["08:00:00", "08:05:00", "08:20:00"]),
            Scenario(
                name: "midnight", latitudes: [0, 1, 2], input: ["23:50:00", "", "24:10:00"],
                expected: ["23:50:00", "24:00:00", "24:10:00"]),
            Scenario(
                name: "multiple segments", latitudes: [0, 1, 4, 5, 8],
                input: ["08:00:00", "", "08:20:00", "", "08:40:00"],
                expected: ["08:00:00", "08:05:00", "08:20:00", "08:25:00", "08:40:00"]),
            Scenario(
                name: "trailing gap", latitudes: [0, 1, 4, 5], input: ["08:00:00", "", "08:20:00", ""],
                expected: ["08:00:00", "08:05:00", "08:20:00", ""]),
            Scenario(
                name: "leading gap", latitudes: [-1, 0, 1, 4], input: ["", "08:00:00", "", "08:20:00"],
                expected: ["", "08:00:00", "08:05:00", "08:20:00"]),
            Scenario(
                name: "coincident stops", latitudes: [0, 0, 0], input: ["08:00:00", "", "08:20:00"],
                expected: ["08:00:00", "08:00:00", "08:20:00"]),
            Scenario(name: "no anchors", latitudes: [0, 1, 4], input: ["", "", ""], expected: ["", "", ""]),
        ])
    func interpolation(scenario: Scenario) throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            for index in scenario.input.indices {
                try db.execute(
                    sql:
                        "INSERT INTO stops (stop_id,stop_lat,stop_lon,location_type,wheelchair_boarding) VALUES (?, ?, 0, 0, 0)",
                    arguments: ["S\(index)", scenario.latitudes[index]])
                let arrival = scenario.input[index]
                // Distinct departure and timepoint values make preservation observable.
                let departure = arrival.isEmpty ? "" : "09:59:00"
                try db.execute(
                    sql:
                        "INSERT INTO stop_times (trip_id,stop_id,stop_sequence,arrival_time,departure_time,timepoint) VALUES ('T', ?, ?, ?, ?, 1)",
                    arguments: ["S\(index)", index + 1, arrival, departure])
            }
            try StopTimeInterpolator.interpolateStopTimes(in: db)
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM stop_times ORDER BY stop_sequence")
            #expect(rows.map { $0["arrival_time"] as String } == scenario.expected)
            let departures = scenario.input.indices.map { index in
                scenario.input[index].isEmpty ? scenario.expected[index] : "09:59:00"
            }
            #expect(rows.map { $0["departure_time"] as String } == departures)
            let timepoints = scenario.input.indices.map { index in
                scenario.input[index].isEmpty && !scenario.expected[index].isEmpty ? 0 : 1
            }
            #expect(rows.map { $0["timepoint"] as Int } == timepoints)
        }
    }

    @Test("Updates distinguish trips and repeated visits to a stop; a second run is unchanged")
    func updateIdentity() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try db.execute(
                sql: """
                    INSERT INTO trips (trip_id,route_id,service_id) VALUES ('U','R','S');
                    INSERT INTO stop_times (trip_id,stop_id,stop_sequence,arrival_time,departure_time,timepoint) VALUES
                    ('T','A',1,'08:00:00','08:01:00',1),
                    ('T','B',2,'','',1),
                    ('T','A',3,'08:20:00','08:21:00',0),
                    ('U','B',2,'10:00:00','10:01:00',1);
                    """)
            try StopTimeInterpolator.interpolateStopTimes(in: db)
            let sql =
                "SELECT trip_id,stop_sequence,arrival_time,departure_time,timepoint FROM stop_times ORDER BY trip_id,stop_sequence"
            let first = try Row.fetchAll(db, sql: sql)
            #expect(first.map { $0["arrival_time"] as String } == ["08:00:00", "08:10:00", "08:20:00", "10:00:00"])
            #expect(first.map { $0["departure_time"] as String } == ["08:01:00", "08:10:00", "08:21:00", "10:01:00"])
            #expect(first.map { $0["timepoint"] as Int } == [1, 0, 0, 1])
            try StopTimeInterpolator.interpolateStopTimes(in: db)
            #expect(try Row.fetchAll(db, sql: sql) == first)
        }
    }
}
