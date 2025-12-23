//
//  CalendarDateImportingTests.swift
//  gtfs-importerTests
//
//  Tests for CalendarDate CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("CalendarDate Importing Tests")
struct CalendarDateImportingTests {

    @Test("fileName returns correct CSV file name")
    func testFileName() {
        #expect(CalendarDate.fileName == "calendar_dates.txt")
    }

    @Test("Import reads and inserts calendar date exceptions from CSV")
    func testImportFromCSV() throws {
        // Create CSV with calendar date exceptions
        let csvContent = """
        service_id,date,exception_type
        WEEKDAY,20240704,2
        WEEKDAY,20241225,2
        WEEKEND,20240101,1
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("calendar_dates.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try CalendarDate.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try CalendarDate.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (3 calendar date exceptions)
        let count = try db.read { db in
            try CalendarDate.fetchCount(db)
        }
        #expect(count == 3, "Should import 3 calendar date exceptions")

        // Verify data and exception types
        let weekdayDates = try db.read { db in
            try CalendarDate.fetchAll(db, sql: "SELECT * FROM calendar_dates WHERE service_id = 'WEEKDAY' ORDER BY date")
        }
        #expect(weekdayDates.count == 2)
        #expect(weekdayDates[0].exceptionType == .removed)
        #expect(weekdayDates[1].exceptionType == .removed)

        // Verify dates as strings from database
        let date1 = try db.read { db in
            try String.fetchOne(db, sql: "SELECT date FROM calendar_dates WHERE service_id = 'WEEKDAY' ORDER BY date LIMIT 1")
        }
        let date2 = try db.read { db in
            try String.fetchOne(db, sql: "SELECT date FROM calendar_dates WHERE service_id = 'WEEKDAY' ORDER BY date LIMIT 1 OFFSET 1")
        }
        #expect(date1 == "2024-07-04")
        #expect(date2 == "2024-12-25")

        // Verify added service
        let addedDates = try db.read { db in
            try CalendarDate.fetchAll(db, sql: "SELECT * FROM calendar_dates WHERE service_id = 'WEEKEND'")
        }
        #expect(addedDates.count == 1)
        #expect(addedDates[0].exceptionType == .added)
    }

    @Test("Import parses dates in yyyyMMdd format correctly")
    func testDateParsing() throws {
        // Create CSV with various date formats
        let csvContent = """
        service_id,date,exception_type
        SERVICE1,20240229,2
        SERVICE2,20241231,1
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("calendar_dates.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try CalendarDate.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try CalendarDate.receiveImport(from: reader, with: db)
            }
        }

        // Verify dates parsed correctly - query as strings from database
        let count = try db.read { db in
            try CalendarDate.fetchCount(db)
        }
        #expect(count == 2)

        let date1 = try db.read { db in
            try String.fetchOne(db, sql: "SELECT date FROM calendar_dates ORDER BY date LIMIT 1")
        }
        let date2 = try db.read { db in
            try String.fetchOne(db, sql: "SELECT date FROM calendar_dates ORDER BY date LIMIT 1 OFFSET 1")
        }
        #expect(date1 == "2024-02-29", "Leap year date should be stored correctly")
        #expect(date2 == "2024-12-31", "New Year's Eve date should be stored correctly")
    }
}
