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

@Suite("StopTime Importing Tests", .serialized)
struct StopTimeImportingTests {

    @Test("Import reads and inserts stop time data from CSV using real data")
    func testImportFromCSV() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)
        defer {
            Thread.sleep(forTimeInterval: 0.1)
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Use real small dataset
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Verify import (small dataset has 130 stop_times)
        let db = try DatabaseQueue(path: "./gtfs.db")
        let count = try db.read { db in
            try StopTime.fetchCount(db)
        }
        #expect(count == 130, "Should import 130 stop times from small real dataset")

        // Verify data structure from real VTA data
        let stopTimes = try db.read { db in
            try StopTime.fetchAll(db, sql: "SELECT * FROM stop_times WHERE trip_id = '3640965' ORDER BY stop_sequence")
        }
        #expect(stopTimes.count == 26, "Trip 3640965 has 26 stops")
        #expect(stopTimes[0].stopIdentifier == "4736")
        #expect(stopTimes[0].stopSequence == 1)
        #expect(stopTimes[0].timepoint == .exact) // Real data has timepoint=1
    }

    @Test("updateLastStop marks final stops in each trip")
    func testUpdateLastStop() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)
        defer {
            Thread.sleep(forTimeInterval: 0.1)
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Import real data using the importer
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Verify last stops are marked (5 trips in small dataset)
        let db = try DatabaseQueue(path: "./gtfs.db")
        let lastStopsCount = try db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stop_times WHERE is_laststop = 1") ?? 0
        }
        #expect(lastStopsCount == 5, "Should have 5 last stops marked (one per trip)")

        // Verify specific trip's last stop
        try db.read { db in
            let trip1LastStop = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = '3640965' ORDER BY stop_sequence DESC LIMIT 1") ?? false
            #expect(trip1LastStop == true, "Trip 3640965's last stop should be marked")

            // Verify first stop is NOT marked
            let trip1FirstStop = try Bool.fetchOne(db, sql: "SELECT is_laststop FROM stop_times WHERE trip_id = '3640965' ORDER BY stop_sequence ASC LIMIT 1") ?? false
            #expect(trip1FirstStop == false, "Trip 3640965's first stop should not be marked")
        }
    }
}
