//
//  ShapeImportingTests.swift
//  gtfs-importerTests
//
//  Tests for Shape CSV importing
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("Shape Importing Tests")
struct ShapeImportingTests {

    @Test("fileName returns correct CSV file name")
    func testFileName() {
        #expect(Shape.fileName == "shapes.txt")
    }

    @Test("Import reads and inserts shape data from CSV")
    func testImportFromCSV() throws {
        // Create CSV with shape points
        let csvContent = """
        shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence
        SHAPE1,37.3347,-121.8906,1
        SHAPE1,37.3357,-121.8916,2
        SHAPE1,37.3367,-121.8926,3
        SHAPE2,37.4000,-121.9000,1
        SHAPE2,37.4010,-121.9010,2
        """

        let tempDir = try TemporaryFileHelper.createTemporaryDirectory()
        defer { TemporaryFileHelper.cleanup(directory: tempDir) }

        let csvPath = tempDir.appendingPathComponent("shapes.txt")
        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)

        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Shape.createTable(db: db)
        }

        guard let stream = InputStream(url: csvPath) else {
            throw ImporterError.invalidStream(path: csvPath.path)
        }

        let reader = try CSVReader(stream: stream, hasHeaderRow: true)

        try db.write { db in
            while reader.next() != nil {
                try Shape.receiveImport(from: reader, with: db)
            }
        }

        // Verify import (5 shape points)
        let count = try db.read { db in
            try Shape.fetchCount(db)
        }
        #expect(count == 5, "Should import 5 shape points")

        // Verify data for first shape point
        let shapePoints = try db.read { db in
            try Shape.fetchAll(db, sql: "SELECT * FROM shapes WHERE shape_id = 'SHAPE1' ORDER BY shape_pt_sequence")
        }
        #expect(shapePoints.count == 3)
        #expect(shapePoints[0].latitude == 37.3347)
        #expect(shapePoints[0].longitude == -121.8906)
        #expect(shapePoints[0].sequence == 1)
    }
}
