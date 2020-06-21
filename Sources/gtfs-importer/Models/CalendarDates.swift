//
//  CalendarDates.swift
//  
//
//  Created by Vashishtha Jogi on 6/20/20.
//

import Foundation
import CSV
import GRDB

struct CalendarDates {
    enum ExceptionType: Int, Codable {
        case added = 1
        case removed = 2
    }
    var serviceIdentifier: String
    var date: Date
    var exceptionType: ExceptionType
}

// For diffing
extension CalendarDates: Hashable {}

extension CalendarDates: Codable, PersistableRecord {
    static let databaseDateEncodingStrategy: DatabaseDateEncodingStrategy = .formatted(DateFormatter.yyyyMMddDash)
    static var databaseTableName = "calendar_dates"
    
    private enum Columns {
        static let serviceIdentifier = Column(CodingKeys.serviceIdentifier)
        static let date = Column(CodingKeys.date)
        static let exceptionType = Column(CodingKeys.exceptionType)
    }
    
    enum CodingKeys: String, CodingKey {
        case serviceIdentifier = "service_id"
        case date = "date"
        case exceptionType = "exception_type"
    }
}

extension CalendarDates: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "calendar_dates.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let decoder = CSVRowDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
            let record = try decoder.decode(Self.self, from: reader)
            try record.insert(db)
        }
    }
    
    // MARK:- DatabaseCreating
    static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: "calendar_dates")
            } catch {
                print("Table calendar_dates does not exist.")
            }
            
            // now create new table
            try db.create(table: "calendar_dates") { t in
                t.column("service_id", .text).notNull().indexed()
                t.column("date", .date).notNull()
                t.column("exception_type", .integer).notNull()
            }
        }
    }
}

extension CalendarDates: CustomStringConvertible {
    var description: String {
        return "\(serviceIdentifier): \(date) - \(exceptionType)"
    }
}
