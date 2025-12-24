//
//  TripImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Trip CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Trip Importing Tests", .serialized)
struct TripImportingTests {

    @Test("Import reads and inserts trip data from CSV using real data")
    func testImportFromCSV() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)
        defer {
            Thread.sleep(forTimeInterval: 0.1)
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Import real data
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Verify import (small dataset has 5 trips)
        let db = try DatabaseQueue(path: "./gtfs.db")
        let count = try db.read { db in
            try Trip.fetchCount(db)
        }
        #expect(count == 5, "Should import 5 trips from small real dataset")

        // Verify data from real VTA data
        let trip = try db.read { db in
            try Trip.fetchOne(db, key: "3640965")
        }
        #expect(trip != nil)
        #expect(trip?.routeIdentifier == "Blue")
        #expect(trip?.serviceIdentifier == "268.2969.1")
        #expect(trip?.wheelchairAccessible == .noInformation) // Real VTA data
        #expect(trip?.bikesAllowed == .noInformation) // Real VTA data
    }
}
