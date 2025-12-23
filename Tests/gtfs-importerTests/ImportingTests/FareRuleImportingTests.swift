//
//  FareRuleImportingTests.swift
//  gtfs-importerTests
//
//  Tests for FareRule CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("FareRule Importing Tests")
struct FareRuleImportingTests {

    @Test("fileName returns correct CSV file name")
    func testFileName() {
        #expect(FareRule.fileName == "fare_rules.txt")
    }

    @Test("Import reads and inserts fare rule data from CSV")
    func testImportFromCSV() throws {
        // Create CSV with fare rules
        let csvContent = """
        fare_id,route_id
        FARE1,ROUTE1
        FARE1,ROUTE2
        FARE2,ROUTE3
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("fare_rules.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try FareRule.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try FareRule.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (3 fare rules)
        let count = try db.read { db in
            try FareRule.fetchCount(db)
        }
        #expect(count == 3, "Should import 3 fare rules")

        // Verify data
        let rules = try db.read { db in
            try FareRule.fetchAll(db, sql: "SELECT * FROM fare_rules WHERE fare_id = 'FARE1' ORDER BY route_id")
        }
        #expect(rules.count == 2)
        #expect(rules[0].routeIdentifier == "ROUTE1")
        #expect(rules[1].routeIdentifier == "ROUTE2")
    }
}
