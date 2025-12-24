//
//  AgencyImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Agency CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Agency Importing Tests")
struct AgencyImportingTests {

    @Test("Import reads and inserts agency data from CSV using real data")
    func testImportFromCSV() throws {
        // Use real small dataset
        let gtfsDir = URL(fileURLWithPath: TestDataHelper.smallRealTestDataPath())

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
        }

        // Import from CSV
        let fileURL = gtfsDir.appendingPathComponent("agency.txt")
        guard let stream = InputStream(url: fileURL) else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Agency.receiveImport(from: reader, with: db)
            }
        }

        // Verify import
        let count = try db.read { db in
            try Agency.fetchCount(db)
        }
        #expect(count == 1, "Should import 1 agency from small real dataset")

        // Verify real VTA data
        let agency = try db.read { db in
            try Agency.fetchOne(db, key: "VTA")
        }
        #expect(agency != nil)
        #expect(agency?.name == "VTA")
        #expect(agency?.url.absoluteString == "https://www.vta.org")
        #expect(agency?.timezone == "America/Los_Angeles")
    }

    @Test("Import handles all fields correctly")
    func testAllFields() throws {
        // Create CSV with all fields to test complete field handling
        let csvContent = """
        agency_id,agency_name,agency_url,agency_timezone,agency_lang,agency_phone,agency_fare_url,agency_email
        VTA,Santa Clara VTA,https://www.vta.org,America/Los_Angeles,en,408-321-2300,https://www.vta.org/fares,service@vta.org
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("agency.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        // Import
        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Agency.receiveImport(from: reader, with: db)
            }
        }

        // Verify all fields
        let agency = try db.read { db in
            try Agency.fetchOne(db, key: "VTA")
        }

        #expect(agency != nil)
        #expect(agency?.identifier == "VTA")
        #expect(agency?.name == "Santa Clara VTA")
        #expect(agency?.language == "en")
        #expect(agency?.phone == "408-321-2300")
        #expect(agency?.email == "service@vta.org")
    }
}
