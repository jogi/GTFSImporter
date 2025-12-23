//
//  StopTimeInterpolatorTests.swift
//  gtfs-importerTests
//
//  Tests for StopTimeInterpolator utility
//

import Foundation
import GRDB
import Testing
import GTFSModel
@testable import gtfs_importer

@Suite("StopTimeInterpolator Tests")
struct StopTimeInterpolatorTests {

    @Test("Interpolation fills missing times based on distance")
    func testBasicInterpolation() throws {
        let db = try DatabaseTestHelper.createTemporaryDatabase()
        defer { try? DatabaseTestHelper.cleanup(database: db) }

        try db.write { db in
            // Create schema
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)

            // Insert test data
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('R1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('T1', 'R1', 'S1')")

            // Create 5 stops roughly evenly spaced (each ~0.001 degrees apart ~= 111 meters)
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP2', 37.3357, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP3', 37.3367, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP4', 37.3377, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP5', 37.3387, -121.8906, 0, 0)")

            // Create stop_times with only first and last having times
            // First stop at 08:00:00, last at 08:20:00 (20 minutes total)
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP1', 1, '08:00:00', '08:00:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP2', 2, '', '')")  // Empty time
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP3', 3, '', '')")  // Empty time
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP4', 4, '', '')")  // Empty time
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP5', 5, '08:20:00', '08:20:00')")

            // Run interpolation
            try StopTimeInterpolator.interpolateStopTimes(in: db)

            // Verify all stop_times now have times
            let stopTimesWithNullTimes = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM stop_times WHERE trip_id = 'T1' AND arrival_time IS NULL
            """) ?? 0
            #expect(stopTimesWithNullTimes == 0, "All stop times should have arrival times after interpolation")

            // Verify timepoint field is set correctly
            // Original timepoints should still have timepoint value (or it was set during import)
            // Interpolated stops should have timepoint=0
            let interpolatedStops = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM stop_times
                WHERE trip_id = 'T1'
                AND stop_sequence IN (2, 3, 4)
                AND timepoint = 0
            """) ?? 0
            #expect(interpolatedStops == 3, "Interpolated stops should have timepoint=0")

            // Verify times are between start and end
            let stop2Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 2")
            let stop3Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 3")
            let stop4Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 4")

            #expect(stop2Time != nil)
            #expect(stop3Time != nil)
            #expect(stop4Time != nil)

            // Times should be ordered
            #expect(stop2Time! > "08:00:00" && stop2Time! < "08:20:00")
            #expect(stop3Time! > stop2Time! && stop3Time! < "08:20:00")
            #expect(stop4Time! > stop3Time! && stop4Time! < "08:20:00")
        }
    }

    @Test("Interpolation preserves existing times")
    func testPreservesExistingTimes() throws {
        let db = try DatabaseTestHelper.createTemporaryDatabase()
        defer { try? DatabaseTestHelper.cleanup(database: db) }

        try db.write { db in
            // Create schema
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)

            // Insert test data
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('R1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('T1', 'R1', 'S1')")

            // Create stops
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP2', 37.3357, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP3', 37.3367, -121.8906, 0, 0)")

            // All stops have times already
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP1', 1, '08:00:00', '08:00:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP2', 2, '08:10:00', '08:10:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP3', 3, '08:20:00', '08:20:00')")

            // Run interpolation
            try StopTimeInterpolator.interpolateStopTimes(in: db)

            // Verify times remain unchanged
            let stop1Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 1")
            let stop2Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 2")
            let stop3Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 3")

            #expect(stop1Time == "08:00:00")
            #expect(stop2Time == "08:10:00")
            #expect(stop3Time == "08:20:00")
        }
    }

    @Test("Interpolation handles overnight times")
    func testOvernightTimes() throws {
        let db = try DatabaseTestHelper.createTemporaryDatabase()
        defer { try? DatabaseTestHelper.cleanup(database: db) }

        try db.write { db in
            // Create schema
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)

            // Insert test data
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('R1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('T1', 'R1', 'S1')")

            // Create stops
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP2', 37.3357, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP3', 37.3367, -121.8906, 0, 0)")

            // Times span midnight (23:50:00 to 00:10:00, represented as 24:10:00 in GTFS)
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP1', 1, '23:50:00', '23:50:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP2', 2, '', '')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('T1', 'STOP3', 3, '24:10:00', '24:10:00')")

            // Run interpolation
            try StopTimeInterpolator.interpolateStopTimes(in: db)

            // Verify interpolated time is between start and end
            let stop2Time = try String.fetchOne(db, sql: "SELECT arrival_time FROM stop_times WHERE trip_id = 'T1' AND stop_sequence = 2")
            #expect(stop2Time != nil)
            // Should be around 00:00:00 (midnight), represented as 24:00:00 in GTFS
            #expect(stop2Time! > "23:50:00")
        }
    }

    @Test("Interpolation handles empty trip gracefully")
    func testEmptyTrip() throws {
        let db = try DatabaseTestHelper.createTemporaryDatabase()
        defer { try? DatabaseTestHelper.cleanup(database: db) }

        try db.write { db in
            // Create schema
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)

            // No stop_times inserted

            // Run interpolation - should not crash
            try StopTimeInterpolator.interpolateStopTimes(in: db)
        }
    }
}
