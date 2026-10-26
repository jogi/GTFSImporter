//
//  Importer.swift
//
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import CSV
import Foundation
import GRDB
import GTFSModel
import OSLog

enum ImporterError: LocalizedError, Equatable {
    case invalidStream(path: String)
    case invalidTime(time: String)

    var errorDescription: String? {
        switch self {
        case .invalidStream(let path):
            return "Cannot create an InputStream for file at path \(path)"
        case .invalidTime(let time):
            return "Invalid time string: \(time)"
        }
    }
}

struct FileImportSummary: Equatable {
    let fileName: String
    var accepted = 0
    var rejected = 0
}

enum ImportDiagnostics {
    static func rejected(_ recordType: Any.Type, error: Error, row: [String]?) {
        let message = "Error importing \(recordType): \(error)\nRejected row: \(row ?? [])\n"
        Logger.importer.error("\(message)")
        FileHandle.standardError.write(Data(message.utf8))
    }
}

private enum SharedCSVDecoders {
    nonisolated(unsafe) static let standard = CSVRowDecoder()
    nonisolated(unsafe) static let yyyyMMdd: CSVRowDecoder = {
        let decoder = CSVRowDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
        return decoder
    }()
}

extension CSVRowDecoder {
    static var shared: CSVRowDecoder { SharedCSVDecoders.standard }
    static var sharedYYYYMMdd: CSVRowDecoder { SharedCSVDecoders.yyyyMMdd }
}

protocol ImporterReceiving {
    @discardableResult
    static func receiveImport(from reader: CSVReader, with db: Database) throws -> Bool
}

extension ImporterReceiving where Self: Codable, Self: PersistableRecord {
    @discardableResult
    static func receiveImport(from reader: CSVReader, with db: Database) throws -> Bool {
        do {
            let record = try CSVRowDecoder.shared.decode(Self.self, from: reader)
            try record.insert(db)
            return true
        } catch {
            ImportDiagnostics.rejected(Self.self, error: error, row: reader.currentRow)
            return false
        }
    }
}

protocol ImporterImporting: ImporterReceiving, DatabaseCreating, TableRecord {
    static var fileName: String { get }
}

extension ImporterImporting {
    @discardableResult
    static func importFile(from path: String, into db: Database, optional: Bool = false) throws -> FileImportSummary {
        var summary = FileImportSummary(fileName: fileName)
        let fileURL = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(fileName)
        if optional && !FileManager.default.fileExists(atPath: fileURL.path) {
            try createTable(db: db)
            print("Skipping \(fileName.magenta) (optional file not found)".yellow)
            return summary
        }
        guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
            FileManager.default.isReadableFile(atPath: fileURL.path),
            let stream = InputStream(url: fileURL)
        else {
            throw ImporterError.invalidStream(path: fileURL.path)
        }
        let reader = try CSVReader(stream: stream, hasHeaderRow: true)
        try createTable(db: db)
        while reader.next() != nil {
            if try receiveImport(from: reader, with: db) {
                summary.accepted += 1
            } else {
                summary.rejected += 1
            }
        }
        if let error = reader.error {
            // CSV.swift 2.5 reports a short byte read at normal EOF as cannotReadFile.
            // Preserve real stream/decoding errors without treating EOF as a failure.
            switch error {
            case CSVError.cannotReadFile where stream.streamStatus == .atEnd: break
            default: throw error
            }
        }
        if summary.rejected > 0 {
            print(
                "Imported \(String(summary.accepted).green) rows into \(databaseTableName.magenta) (\(String(summary.rejected).yellow) rejected)"
            )
        } else {
            print("Imported \(String(summary.accepted).green) rows into \(databaseTableName.magenta)")
        }
        return summary
    }
}

struct Importer {
    static let defaultDatabaseFileName = "gtfs.db"
    var path: String
    let database: DatabaseQueue

    /// Replace a feed atomically. Malformed rows are logged and skipped; file errors
    /// abort the import and preserve the previously committed feed.
    @discardableResult
    func importAllFiles() throws -> [FileImportSummary] {
        try database.write { db in
            var summaries: [FileImportSummary] = []
            // Drop children before parents so a second import respects foreign keys.
            for table in [
                "stop_times", "trips", "shapes", "routes", "stops", "directions",
                "fare_rules", "fare_attributes", "calendar_dates", "calendar", "agency",
            ] {
                try db.execute(sql: "DROP TABLE IF EXISTS \(table)")
            }
            summaries.append(try Agency.importFile(from: path, into: db))
            summaries.append(try Calendar.importFile(from: path, into: db))
            summaries.append(try CalendarDate.importFile(from: path, into: db, optional: true))
            summaries.append(try FareAttribute.importFile(from: path, into: db, optional: true))
            summaries.append(try FareRule.importFile(from: path, into: db, optional: true))
            summaries.append(try Direction.importFile(from: path, into: db, optional: true))
            summaries.append(try Stop.importFile(from: path, into: db))
            summaries.append(try Route.importFile(from: path, into: db))
            summaries.append(try Shape.importFile(from: path, into: db, optional: true))
            summaries.append(try Trip.importFile(from: path, into: db))
            summaries.append(try StopTime.importFile(from: path, into: db))
            try StopTime.updateLastStop(in: db)
            try StopTimeInterpolator.interpolateStopTimes(in: db)
            return summaries
        }
    }

    /// The command workflow, with storage supplied by the caller.
    @discardableResult
    func run(addStopRoutes: Bool) throws -> [FileImportSummary] {
        let summaries = try importAllFiles()
        try database.write { db in
            if addStopRoutes {
                try StopRoute.addStopRoutes(in: db)
                print("Added stop routes to \("stops".magenta)")
            }
        }
        try database.vacuum()
        return summaries
    }
}
