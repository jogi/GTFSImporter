//
//  FareAttributeImportingTests.swift
//  gtfs-importerTests
//
//  Tests for FareAttribute CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("FareAttribute Importing Tests")
struct FareAttributeImportingTests {

    @Test("fileName returns correct CSV file name")
    func testFileName() {
        #expect(FareAttribute.fileName == "fare_attributes.txt")
    }

    @Test("Import reads and inserts fare attribute data from CSV")
    func testImportFromCSV() throws {
        // Create CSV with fare attributes
        let csvContent = """
        fare_id,price,currency_type,payment_method,transfers
        FARE1,2.50,USD,0,0
        FARE2,5.00,USD,1,2
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("fare_attributes.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try FareAttribute.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try FareAttribute.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (2 fare attributes)
        let count = try db.read { db in
            try FareAttribute.fetchCount(db)
        }
        #expect(count == 2, "Should import 2 fare attributes")

        // Verify data
        let fare = try db.read { db in
            try FareAttribute.fetchOne(db, key: "FARE1")
        }
        #expect(fare != nil)
        #expect(fare?.price == 2.50)
        #expect(fare?.currencyType == "USD")
    }
}
