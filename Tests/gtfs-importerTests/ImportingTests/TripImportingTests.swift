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

@Suite("Trip Importing Tests")
struct TripImportingTests {

    @Test("Import reads and inserts trip data from CSV")
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
        }

        // Import dependencies first
        try db.write { db in
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('AGENCY1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE1', 3)")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE2', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('WEEKDAY', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
        }

        let fileURL = gtfsDir.appendingPathComponent("trips.txt")
        guard let stream = InputStream(url: fileURL) else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Trip.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (minimal dataset has 3 trips)
        let count = try db.read { db in
            try Trip.fetchCount(db)
        }
        #expect(count == 3, "Should import 3 trips from minimal dataset")

        // Verify data
        let trip = try db.read { db in
            try Trip.fetchOne(db, key: "TRIP1")
        }
        #expect(trip != nil)
        #expect(trip?.routeIdentifier == "ROUTE1")
        #expect(trip?.serviceIdentifier == "WEEKDAY")
    }

    @Test("Import applies default values for wheelchair and bikes fields")
    func testDefaultValues() throws {
        // Create CSV without optional wheelchair/bikes fields
        let csvContent = """
        route_id,service_id,trip_id
        ROUTE1,SERVICE1,TRIP_NO_DEFAULTS
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("trips.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
        }

        // Insert dependencies
        try db.write { db in
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('SERVICE1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Trip.receiveImport(from: reader, with: db)
            }
        }

        // Verify default values are applied
        let trip = try db.read { db in
            try Trip.fetchOne(db, key: "TRIP_NO_DEFAULTS")
        }

        #expect(trip != nil)
        #expect(trip?.wheelchairAccessible == .noInformation, "Should default to noInformation")
        #expect(trip?.bikesAllowed == .noInformation, "Should default to noInformation")
    }

    @Test("Import preserves explicit wheelchair and bikes values")
    func testExplicitValues() throws {
        // Create CSV with explicit wheelchair/bikes values
        let csvContent = """
        route_id,service_id,trip_id,wheelchair_accessible,bikes_allowed
        ROUTE1,SERVICE1,TRIP_ACCESSIBLE,1,2
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("trips.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
        }

        // Insert dependencies
        try db.write { db in
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type) VALUES ('ROUTE1', 3)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('SERVICE1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Trip.receiveImport(from: reader, with: db)
            }
        }

        // Verify explicit values are preserved
        let trip = try db.read { db in
            try Trip.fetchOne(db, key: "TRIP_ACCESSIBLE")
        }

        #expect(trip != nil)
        #expect(trip?.wheelchairAccessible == .accessible)
        #expect(trip?.bikesAllowed == .notAllowed)
    }
}
