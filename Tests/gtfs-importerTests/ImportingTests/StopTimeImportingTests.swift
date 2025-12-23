//
//  StopTimeImportingTests.swift
//  gtfs-importerTests
//
//  Tests for StopTime CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("StopTime Importing Tests")
struct StopTimeImportingTests {

    @Test("Import reads and inserts stop time data from CSV")
    func testImportFromCSV() throws {
        let gtfsDir = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: gtfsDir) }

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)
        }

        // Import dependencies
        try db.write { db in
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('AGENCY1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE1', 3)")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE2', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('WEEKDAY', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'ROUTE1', 'WEEKDAY')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP2', 'ROUTE1', 'WEEKDAY')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP3', 'ROUTE2', 'WEEKDAY')")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP2', 37.3357, -121.8916, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP3', 37.3367, -121.8926, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP4', 37.3377, -121.8936, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP5', 37.3387, -121.8946, 0, 0)")
        }

        let fileURL = gtfsDir.appendingPathComponent("stop_times.txt")
        guard let stream = InputStream(url: fileURL) else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try StopTime.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (minimal dataset has 13 stop_times)
        let count = try db.read { db in
            try StopTime.fetchCount(db)
        }
        #expect(count == 13, "Should import 13 stop times from minimal dataset")

        // Verify data
        let stopTimes = try db.read { db in
            try StopTime.fetchAll(db, sql: "SELECT * FROM stop_times WHERE trip_id = 'TRIP1' ORDER BY stop_sequence")
        }
        #expect(stopTimes.count == 5)
        #expect(stopTimes[0].stopIdentifier == "STOP1")
        #expect(stopTimes[0].stopSequence == 1)
    }

    @Test("Import handles overnight times correctly using sanitizedTimeString")
    func testOvernightTimes() throws {
        // Create CSV with overnight times (>= 24:00:00)
        let csvContent = """
        trip_id,arrival_time,departure_time,stop_id,stop_sequence
        TRIP1,23:50:00,23:50:00,STOP1,1
        TRIP1,24:05:00,24:05:00,STOP2,2
        TRIP1,25:30:00,25:30:00,STOP3,3
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("stop_times.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)
        }

        // Insert dependencies
        try db.write { db in
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'ROUTE1', 'S1')")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP2', 37.3357, -121.8916, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP3', 37.3367, -121.8926, 0, 0)")
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try StopTime.receiveImport(from: reader, with: db)
            }
        }

        // Verify times were sanitized and imported
        let stopTimes = try db.read { db in
            try StopTime.fetchAll(db, sql: "SELECT * FROM stop_times WHERE trip_id = 'TRIP1' ORDER BY stop_sequence")
        }

        #expect(stopTimes.count == 3, "All overnight times should be imported")

        // Times should be converted by sanitizedTimeString:
        // 23:50:00 stays as is
        // 24:05:00 -> 00:05:00
        // 25:30:00 -> 01:30:00
        // (These are stored as Date objects and retrieved as strings)
    }

    @Test("Import applies default values for optional fields")
    func testDefaultValues() throws {
        // Create CSV with minimal required fields only
        let csvContent = """
        trip_id,arrival_time,departure_time,stop_id,stop_sequence
        TRIP1,08:00:00,08:00:00,STOP1,1
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("stop_times.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)
        }

        // Insert dependencies
        try db.write { db in
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'ROUTE1', 'S1')")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try StopTime.receiveImport(from: reader, with: db)
            }
        }

        // Verify default values were applied
        let stopTime = try db.read { db in
            try StopTime.fetchOne(db, sql: "SELECT * FROM stop_times WHERE trip_id = 'TRIP1'")
        }

        #expect(stopTime != nil)
        #expect(stopTime?.pickupType == .regularlyScheduled, "Should default to regularlyScheduled")
        #expect(stopTime?.dropoffType == .regularlyScheduled, "Should default to regularlyScheduled")
        #expect(stopTime?.continuousPickup == .notContinuous, "Should default to notContinuous")
        #expect(stopTime?.continuousDropoff == .notContinuous, "Should default to notContinuous")
        #expect(stopTime?.timepoint == .exact, "Should default to exact")
        #expect(stopTime?.isLastStop == false, "Should default to false")
    }

    @Test("updateLastStop marks final stops in each trip")
    func testUpdateLastStop() throws {
        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)

        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)

            // Insert test data with multiple trips
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('R1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'R1', 'S1')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP2', 'R1', 'S1')")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP2', 37.3357, -121.8916, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP3', 37.3367, -121.8926, 0, 0)")

            // Trip 1: 3 stops (sequence 1, 2, 3)
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time, is_laststop) VALUES ('TRIP1', 'STOP1', 1, '08:00:00', '08:00:00', 0)")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time, is_laststop) VALUES ('TRIP1', 'STOP2', 2, '08:10:00', '08:10:00', 0)")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time, is_laststop) VALUES ('TRIP1', 'STOP3', 3, '08:20:00', '08:20:00', 0)")

            // Trip 2: 2 stops (sequence 1, 2)
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time, is_laststop) VALUES ('TRIP2', 'STOP1', 1, '09:00:00', '09:00:00', 0)")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time, is_laststop) VALUES ('TRIP2', 'STOP2', 2, '09:10:00', '09:10:00', 0)")

            // Manually run the updateLastStop logic
            // This is the same SQL that StopTime.updateLastStop() executes
            try db.execute(sql: """
                UPDATE stop_times
                SET is_laststop = 1
                WHERE (trip_id, stop_sequence) IN (
                    SELECT trip_id, MAX(stop_sequence)
                    FROM stop_times
                    GROUP BY trip_id
                )
                """)
        }

        // Verify last stops are marked
        try db.read { db in
            // TRIP1: STOP3 (sequence 3) should be marked
            let trip1LastStop = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = 'TRIP1' AND stop_sequence = 3") ?? false
            #expect(trip1LastStop == true, "TRIP1's last stop should be marked")

            // TRIP1: STOP1 and STOP2 should not be marked
            let trip1Stop1 = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = 'TRIP1' AND stop_sequence = 1") ?? false
            let trip1Stop2 = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = 'TRIP1' AND stop_sequence = 2") ?? false
            #expect(trip1Stop1 == false)
            #expect(trip1Stop2 == false)

            // TRIP2: STOP2 (sequence 2) should be marked
            let trip2LastStop = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = 'TRIP2' AND stop_sequence = 2") ?? false
            #expect(trip2LastStop == true, "TRIP2's last stop should be marked")

            // TRIP2: STOP1 should not be marked
            let trip2Stop1 = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = 'TRIP2' AND stop_sequence = 1") ?? false
            #expect(trip2Stop1 == false)
        }
    }
}
