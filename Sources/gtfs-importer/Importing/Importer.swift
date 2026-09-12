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

protocol ImporterReceiving {
    static func receiveImport(from reader: CSVReader, with db: Database) throws
}

extension ImporterReceiving where Self: Codable, Self: PersistableRecord {
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let record = try CSVRowDecoder().decode(Self.self, from: reader)
            try record.insert(db)
        } catch {
            Logger.importer.error("Error importing \(Self.self) - \(error)\n\(reader.currentRow ?? [])")
        }
    }
}

protocol ImporterImporting: ImporterReceiving, DatabaseCreating {
    static var fileName: String { get }
}

extension ImporterImporting {
    static func importFile(from path: String, into db: Database, optional: Bool = false) throws {
        let fileURL = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(fileName)
        if optional && !FileManager.default.fileExists(atPath: fileURL.path) {
            try createTable(db: db)
            return
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
            try receiveImport(from: reader, with: db)
        }
        if let error = reader.error {
            // CSV.swift 2.5 reports a short byte read at normal EOF as cannotReadFile.
            // Preserve real stream/decoding errors without treating EOF as a failure.
            switch error {
            case CSVError.cannotReadFile where stream.streamStatus == .atEnd: break
            default: throw error
            }
        }
    }
}

struct Importer {
    static let defaultDatabaseFileName = "gtfs.db"
    var path: String
    let database: DatabaseQueue

    /// Replace a feed atomically. Malformed rows are logged and skipped; file errors
    /// abort the import and preserve the previously committed feed.
    func importAllFiles() throws {
        try database.write { db in
            // Drop children before parents so a second import respects foreign keys.
            for table in [
                "stop_times", "trips", "shapes", "routes", "stops", "directions",
                "fare_rules", "fare_attributes", "calendar_dates", "calendar", "agency",
            ] {
                try db.execute(sql: "DROP TABLE IF EXISTS \(table)")
            }
            try Agency.importFile(from: path, into: db)
            try Calendar.importFile(from: path, into: db)
            try CalendarDate.importFile(from: path, into: db, optional: true)
            try FareAttribute.importFile(from: path, into: db, optional: true)
            try FareRule.importFile(from: path, into: db, optional: true)
            try Direction.importFile(from: path, into: db, optional: true)
            try Stop.importFile(from: path, into: db)
            try Route.importFile(from: path, into: db)
            try Shape.importFile(from: path, into: db, optional: true)
            try Trip.importFile(from: path, into: db)
            try StopTime.importFile(from: path, into: db)
            try StopTime.updateLastStop(in: db)
            try StopTimeInterpolator.interpolateStopTimes(in: db)
            try StopTime.normalizeServiceDayTimes(in: db)
        }
    }

    /// The command workflow, with storage supplied by the caller.
    func run(addStopRoutes: Bool) throws {
        try importAllFiles()
        try database.write { db in
            if addStopRoutes { try StopRoute.addStopRoutes(in: db) }
        }
        try database.vacuum()
        try database.writeWithoutTransaction { try $0.execute(sql: "REINDEX") }
    }
}
