//
//  DirectionImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Direction CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Direction Importing Tests")
struct DirectionImportingTests {

    @Test("fileName returns correct CSV file name")
    func testFileName() {
        #expect(Direction.fileName == "directions.txt")
    }

    @Test("Import reads and inserts direction data from CSV")
    func testImportFromCSV() throws {
        // Create CSV with directions (using DirectionType enum values)
        let csvContent = """
        route_id,direction_id,direction
        ROUTE1,0,Inbound
        ROUTE1,1,Outbount
        ROUTE2,0,North
        ROUTE2,1,South
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("directions.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Direction.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Direction.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (4 directions)
        let count = try db.read { db in
            try Direction.fetchCount(db)
        }
        #expect(count == 4, "Should import 4 directions")

        // Verify data
        let directions = try db.read { db in
            try Direction.fetchAll(db, sql: "SELECT * FROM directions WHERE route_id = 'ROUTE1' ORDER BY direction_id")
        }
        #expect(directions.count == 2)
        #expect(directions[0].identifier == 0)
        #expect(directions[0].routeIdentifier == "ROUTE1")
        #expect(directions[1].identifier == 1)
        #expect(directions[1].routeIdentifier == "ROUTE1")
    }
}
