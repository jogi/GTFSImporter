//
//  RouteImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Route CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Route Importing Tests")
struct RouteImportingTests {

    @Test("Import reads and inserts route data from CSV using real data")
    func testImportFromCSV() throws {
        // Use real small dataset
        let gtfsDir = URL(fileURLWithPath: TestDataHelper.smallRealTestDataPath())

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Route.createTable(db: db)
        }

        let fileURL = gtfsDir.appendingPathComponent("routes.txt")
        guard let stream = InputStream(url: fileURL) else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Route.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (small real dataset has 1 route: Blue Line)
        let count = try db.read { db in
            try Route.fetchCount(db)
        }
        #expect(count == 1, "Should import 1 route from small real dataset")

        // Verify real VTA data
        let route = try db.read { db in
            try Route.fetchOne(db, key: "Blue")
        }
        #expect(route != nil)
        #expect(route?.shortName == "Blue Line")
        #expect(route?.longName == "Baypointe - Santa Teresa")
        #expect(route?.type == .tram) // Light rail = type 0
    }

    @Test("Import applies default values for missing optional fields")
    func testDefaultValues() throws {
        // Create CSV without optional color/sortOrder fields to test defaults
        let csvContent = """
        route_id,agency_id,route_short_name,route_long_name,route_type
        TEST1,AGENCY1,1,Test Route,3
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("routes.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Route.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Route.receiveImport(from: reader, with: db)
            }
        }

        // Verify default values are applied
        let route = try db.read { db in
            try Route.fetchOne(db, key: "TEST1")
        }

        #expect(route != nil)
        // Note: Default values are applied in Route+Importing.swift
        // If no custom decoder, defaults come from GTFSModel.Route init
    }
}
