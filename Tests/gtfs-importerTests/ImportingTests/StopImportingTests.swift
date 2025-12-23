//
//  StopImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Stop CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Stop Importing Tests")
struct StopImportingTests {

    @Test("fileName returns correct CSV file name")
    func testFileName() {
        #expect(Stop.fileName == "stops.txt")
    }

    @Test("Import reads and inserts stop data from CSV")
    func testImportFromCSV() throws {
        let gtfsDir = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: gtfsDir) }

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Stop.createTable(db: db)
        }

        let fileURL = gtfsDir.appendingPathComponent("stops.txt")
        guard let stream = InputStream(url: fileURL) else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Stop.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (minimal dataset has 5 stops)
        let count = try db.read { db in
            try Stop.fetchCount(db)
        }
        #expect(count == 5, "Should import 5 stops from minimal dataset")

        // Verify data
        let stop = try db.read { db in
            try Stop.fetchOne(db, key: "STOP1")
        }
        #expect(stop != nil)
        #expect(stop?.name == "First Street")
        #expect(stop?.latitude == 37.3347)
        #expect(stop?.longitude == -121.8906)
    }
}
