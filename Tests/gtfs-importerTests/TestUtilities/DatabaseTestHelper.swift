//
//  DatabaseTestHelper.swift
//  gtfs-importerTests
//
//  Test utilities for database operations
//

import Foundation
import GRDB
import GTFSModel

enum DatabaseTestHelper {

    /// Creates a temporary database for testing
    static func createTemporaryDatabase() throws -> DatabaseQueue {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db")
        return try DatabaseQueue(path: dbPath.path)
    }

    /// Closes database connection and deletes the database file
    static func cleanup(database: DatabaseQueue) throws {
        let path = database.path
        try database.close()
        try? FileManager.default.removeItem(atPath: path)
    }

    /// Verifies that a table exists in the database
    static func assertTableExists(_ tableName: String, in db: DatabaseQueue) throws {
        let exists = try db.read { db in
            try db.tableExists(tableName)
        }
        guard exists else {
            throw DatabaseTestError.tableNotFound(tableName)
        }
    }

    /// Returns the number of records in a table
    static func recordCount(in table: String, db: DatabaseQueue) throws -> Int {
        try db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
        }
    }

    /// Asserts that a table has the expected number of records
    static func assertRecordCount(_ expected: Int, in table: String, db: DatabaseQueue) throws {
        let actual = try recordCount(in: table, db: db)
        guard actual == expected else {
            throw DatabaseTestError.unexpectedRecordCount(expected: expected, actual: actual, table: table)
        }
    }

    /// Returns column names for a table
    static func columnNames(for table: String, in db: DatabaseQueue) throws -> [String] {
        try db.read { db in
            try db.columns(in: table).map { $0.name }
        }
    }
}

enum DatabaseTestError: Error {
    case tableNotFound(String)
    case unexpectedRecordCount(expected: Int, actual: Int, table: String)
}
