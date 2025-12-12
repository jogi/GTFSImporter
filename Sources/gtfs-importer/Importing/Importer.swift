//
//  Importer.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel
import OSLog

enum ImporterError: LocalizedError {
    case invalidStream(path: String)
    case invalidTime(time: String)
    
    var errorDescription: String? {
        switch self {
        case let .invalidStream(path):
            return "Cannot create an InputStream for file at path \(path)"
        case let .invalidTime(time):
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

protocol ImporterImporting: ImporterReceiving {
    static var fileName: String { get }
    static var dbQueue: DatabaseQueue? { get }
    
    static func importFile(from path: String) throws
}

extension ImporterImporting where Self: DatabaseCreating {
    static var dbQueue: DatabaseQueue? {
        var configuration = Configuration()
        configuration.publicStatementArguments = true
        return try? DatabaseQueue(path: "./\(Importer.defaultDatabaseFileName)", configuration: configuration)
    }

    static func importFile(from path: String) throws {
        print("Importing from \(fileName.magenta)")
        
        do {
            let fileURL = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(fileName)
            guard let stream = InputStream(url: fileURL) else {
                throw ImporterError.invalidStream(path: fileURL.path)
            }
            
            let startTime = Date()
            
            // First let's cleanup the table
            try dbQueue?.write { db in
                try self.createTable(db: db)
            }
            
            let reader = try CSVReader(stream: stream, hasHeaderRow: true)
            
            var count = 0
            try dbQueue?.write { db in
                while reader.next() != nil {
                    try receiveImport(from: reader, with: db)
                    count += 1
                }
            }
            
            let endTime = Date()

            let model = "\(Self.self)"
            let duration = String(format: "%.2f", endTime.timeIntervalSince(startTime))
            print("Imported \(String(count).green) \(model.magenta) records in \(duration.green) seconds")
        }
    }
}

struct Importer {
    static var defaultDatabaseFileName = "gtfs.db"
    var path: String
    
    func importAllFiles() throws {
        try Agency.importFile(from: path)
        try Calendar.importFile(from: path)
        // Skip calendar_dates - not in legacy schema
        // try CalendarDate.importFile(from: path)
        try FareAttribute.importFile(from: path)
        try FareRule.importFile(from: path)
        // Skip directions - not in legacy schema
        // try Direction.importFile(from: path)
        try Stop.importFile(from: path)
        try Route.importFile(from: path)
        try Shape.importFile(from: path)
        try Trip.importFile(from: path)
        try StopTime.importFile(from: path)
        try StopTime.updateLastStop()
    }
}

