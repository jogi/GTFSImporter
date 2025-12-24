//
//  ImporterTests.swift
//  gtfs-importerTests
//
//  Tests for Importer orchestration
//

import Foundation
import GRDB
import Testing
import GTFSModel
@testable import gtfs_importer

@Suite("Importer Orchestration Tests", .serialized, .tags(.integrationTests))
struct ImporterTests {

    @Test("importAllFiles imports all entities in correct order")
    func testImportAllFiles() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Run the full import with real small dataset
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Verify all entities were imported
        do {
            let db = try DatabaseQueue(path: "./gtfs.db")
            let counts = try db.read { db in
                (
                    agency: try Agency.fetchCount(db),
                    route: try Route.fetchCount(db),
                    stop: try Stop.fetchCount(db),
                    calendar: try GTFSModel.Calendar.fetchCount(db),
                    trip: try Trip.fetchCount(db),
                    stopTime: try StopTime.fetchCount(db)
                )
            }

            #expect(counts.agency == 1, "Should import 1 agency")
            #expect(counts.route == 1, "Should import 1 route")
            #expect(counts.stop == 26, "Should import 26 stops")
            #expect(counts.calendar == 3, "Should import 3 calendar entries")
            #expect(counts.trip == 5, "Should import 5 trips")
            #expect(counts.stopTime == 130, "Should import 130 stop times")
        }  // db closes here
    }

    @Test("importAllFiles creates all required tables")
    func testTableCreation() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        do {
            let db = try DatabaseQueue(path: "./gtfs.db")
            let tables = try db.read { db in
                try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            }

            #expect(tables.contains("agency"), "Should have agency table")
            #expect(tables.contains("routes"), "Should have routes table")
            #expect(tables.contains("stops"), "Should have stops table")
            #expect(tables.contains("calendar"), "Should have calendar table")
            #expect(tables.contains("trips"), "Should have trips table")
            #expect(tables.contains("stop_times"), "Should have stop_times table")
        }  // db closes here
    }

    @Test("importAllFiles runs updateLastStop after stop_times import")
    func testUpdateLastStopExecuted() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Verify last stops are marked
        do {
            let db = try DatabaseQueue(path: "./gtfs.db")
            let lastStopCount = try db.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stop_times WHERE is_laststop = 1") ?? 0
            }

            // Should have 5 last stops (one per trip in small real dataset)
            #expect(lastStopCount == 5, "Should have 5 last stops marked")
        }  // db closes here
    }

    @Test("importAllFiles handles foreign key relationships correctly")
    func testForeignKeyRelationships() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        do {
            let db = try DatabaseQueue(path: "./gtfs.db")
            try db.read { db in
                // Verify trips reference valid routes
                let trips = try Trip.fetchAll(db)
                for trip in trips {
                    let route = try Route.fetchOne(db, key: trip.routeIdentifier)
                    #expect(route != nil, "Trip \(trip.identifier) should reference valid route")
                }

                // Verify trips reference valid calendars
                for trip in trips {
                    let calendar = try GTFSModel.Calendar.fetchOne(db, key: trip.serviceIdentifier)
                    #expect(calendar != nil, "Trip \(trip.identifier) should reference valid calendar")
                }

                // Verify stop_times reference valid trips and stops
                let stopTimes = try StopTime.fetchAll(db)
                for stopTime in stopTimes {
                    let trip = try Trip.fetchOne(db, key: stopTime.tripIdentifier)
                    #expect(trip != nil, "StopTime should reference valid trip")

                    let stop = try Stop.fetchOne(db, key: stopTime.stopIdentifier)
                    #expect(stop != nil, "StopTime should reference valid stop")
                }
            }
        }  // db closes here
    }
}
