//
//  CalendarImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Calendar CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Calendar Importing Tests")
struct CalendarImportingTests {

    @Test("Import reads and inserts calendar data from CSV")
    func testImportFromCSV() throws {
        let gtfsDir = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: gtfsDir) }

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try GTFSModel.Calendar.createTable(db: db)
        }

        let fileURL = gtfsDir.appendingPathComponent("calendar.txt")
        guard let stream = InputStream(url: fileURL) else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try GTFSModel.Calendar.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (minimal dataset has 1 calendar)
        let count = try db.read { db in
            try GTFSModel.Calendar.fetchCount(db)
        }
        #expect(count == 1, "Should import 1 calendar from minimal dataset")

        // Verify data
        let calendar = try db.read { db in
            try GTFSModel.Calendar.fetchOne(db, key: "WEEKDAY")
        }
        #expect(calendar != nil)
        #expect(calendar?.monday == .available)
        #expect(calendar?.saturday == .unavailable)
        #expect(calendar?.sunday == .unavailable)
    }

    @Test("Import parses dates in yyyyMMdd format correctly")
    func testDateParsing() throws {
        // Create CSV with yyyyMMdd date format
        let csvContent = """
        service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
        WEEKDAY,1,1,1,1,1,0,0,20240101,20241231
        WEEKEND,0,0,0,0,0,1,1,20240615,20240915
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("calendar.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try GTFSModel.Calendar.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try GTFSModel.Calendar.receiveImport(from: reader, with: db)
            }
        }

        // Verify dates were parsed and stored correctly
        // Query database directly as strings since dates are Date objects in Swift
        let startDate = try db.read { db in
            try String.fetchOne(db, sql: "SELECT start_date FROM calendar WHERE service_id = 'WEEKDAY'")
        }
        let endDate = try db.read { db in
            try String.fetchOne(db, sql: "SELECT end_date FROM calendar WHERE service_id = 'WEEKDAY'")
        }

        #expect(startDate == "2024-01-01", "Start date should be stored as 2024-01-01")
        #expect(endDate == "2024-12-31", "End date should be stored as 2024-12-31")
    }
}
