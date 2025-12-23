//
//  TemporaryFileHelper.swift
//  gtfs-importerTests
//
//  Helper utilities for temporary file and directory management
//

import Foundation

enum TemporaryFileHelper {

    /// Creates a temporary directory for testing
    static func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("gtfs-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }

    /// Removes a temporary directory and all its contents
    static func cleanup(directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Creates a temporary database path
    static func createTemporaryDatabasePath() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("test-\(UUID().uuidString).db")
    }
}
