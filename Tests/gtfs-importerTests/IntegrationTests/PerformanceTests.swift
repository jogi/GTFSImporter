//
//  PerformanceTests.swift
//  gtfs-importerTests
//
//  Performance and timing tests
//

import Foundation
import GRDB
import Testing
import GTFSModel
@testable import gtfs_importer

@Suite("Performance Tests", .serialized, .tags(.integrationTests))
struct PerformanceTests {

    @Test("Minimal dataset imports in reasonable time")
    func testMinimalDatasetPerformance() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock

        let gtfsDir = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: gtfsDir) }
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        let startTime = Date()

        let importer = Importer(path: gtfsDir.path)
        try importer.importAllFiles()

        let duration = Date().timeIntervalSince(startTime)

        // Minimal dataset should import very quickly (< 5 seconds)
        #expect(duration < 5.0, "Minimal dataset should import in under 5 seconds (took \(String(format: "%.2f", duration))s)")

        // Verify data was imported
        do {
            let db = try DatabaseQueue(path: "./gtfs.db")
            let count = try db.read { db in
                try StopTime.fetchCount(db)
            }
            #expect(count == 13, "Should have imported all stop_times")
        }  // db closes here
    }

    @Test("Database operations complete efficiently")
    func testDatabaseOperationsPerformance() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock

        let gtfsDir = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: gtfsDir) }
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        let importer = Importer(path: gtfsDir.path)
        try importer.importAllFiles()

        do {
            let db = try DatabaseQueue(path: "./gtfs.db")

            // Test read performance
            let readStart = Date()
            try db.read { db in
                _ = try StopTime.fetchAll(db)
                _ = try Trip.fetchAll(db)
                _ = try Stop.fetchAll(db)
            }
            let readDuration = Date().timeIntervalSince(readStart)
            #expect(readDuration < 1.0, "Reads should complete quickly (took \(String(format: "%.2f", readDuration))s)")

            // Test query performance with joins
            let joinStart = Date()
            try db.read { db in
                _ = try StopTime.fetchAll(db, sql: """
                    SELECT st.* FROM stop_times st
                    JOIN trips t ON st.trip_id = t.trip_id
                    JOIN routes r ON t.route_id = r.route_id
                """)
            }
            let joinDuration = Date().timeIntervalSince(joinStart)
            #expect(joinDuration < 1.0, "Join queries should complete quickly (took \(String(format: "%.2f", joinDuration))s)")
        }  // db closes here
    }

    @Test("Interpolation completes in reasonable time", .timeLimit(.minutes(1)))
    func testInterpolationPerformance() throws {
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

            // Create test data with many stops needing interpolation
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('R1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'R1', 'S1')")

            // Create 50 stops
            for i in 1...50 {
                let lat = 37.3347 + Double(i) * 0.001
                try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP\(i)', \(lat), -121.8906, 0, 0)")
            }

            // Create stop_times with only first and last having times (48 need interpolation)
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP1', 'STOP1', 1, '08:00:00', '08:00:00')")
            for i in 2...49 {
                try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP1', 'STOP\(i)', \(i), '', '')")
            }
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP1', 'STOP50', 50, '09:00:00', '09:00:00')")
        }

        // Run interpolation and time it
        let interpolationStart = Date()
        try db.write { database in
            try StopTimeInterpolator.interpolateStopTimes(in: database)
        }
        let interpolationDuration = Date().timeIntervalSince(interpolationStart)

        // Interpolation should complete in under 5 seconds even for 50 stops
        #expect(interpolationDuration < 5.0, "Interpolation should complete quickly (took \(String(format: "%.2f", interpolationDuration))s)")

        // Verify all times were interpolated
        let nullTimeCount = try db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stop_times WHERE arrival_time IS NULL OR arrival_time = ''") ?? 0
        }
        #expect(nullTimeCount == 0, "All times should be interpolated")
    }

    @Test("Full VTA dataset loads successfully", .timeLimit(.minutes(5)), .disabled("Full dataset import can be slow"))
    func testFullVTADataset() throws {
        let vtaDataPath = TestDataHelper.fullTestDataPath()

        // Check if VTA data exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: vtaDataPath) else {
            print("Skipping full VTA test - data not found at \(vtaDataPath)")
            return
        }

        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.1)  // Allow time for file system to release lock
        defer { try? FileManager.default.removeItem(atPath: "./gtfs.db") }

        let startTime = Date()

        let importer = Importer(path: vtaDataPath)
        try importer.importAllFiles()

        let duration = Date().timeIntervalSince(startTime)

        print("Full VTA import completed in \(String(format: "%.2f", duration)) seconds")

        // Verify significant data was imported
        let db = try DatabaseQueue(path: "./gtfs.db")
        try db.read { db in
            let stopTimeCount = try StopTime.fetchCount(db)
            let tripCount = try Trip.fetchCount(db)
            let stopCount = try Stop.fetchCount(db)

            #expect(stopTimeCount > 100000, "Should import many stop_times from VTA data")
            #expect(tripCount > 1000, "Should import many trips from VTA data")
            #expect(stopCount > 1000, "Should import many stops from VTA data")

            print("Imported \(stopTimeCount) stop_times, \(tripCount) trips, \(stopCount) stops")
        }
    }
}
