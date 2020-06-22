//
//  Calendar+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB

extension Calendar: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "calendar.txt"
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
                try db.drop(table: Calendar.databaseTableName)
            } catch {
                print("Table \(Calendar.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Calendar.databaseTableName) { t in
                t.column(CodingKeys.serviceIdentifier.rawValue, .text).notNull().indexed()
                t.column(CodingKeys.startDate.rawValue, .date).notNull()
                t.column(CodingKeys.endDate.rawValue, .date).notNull()
                t.column(CodingKeys.monday.rawValue, .integer).notNull()
                t.column(CodingKeys.tuesday.rawValue, .integer).notNull()
                t.column(CodingKeys.wednesday.rawValue, .integer).notNull()
                t.column(CodingKeys.thursday.rawValue, .integer).notNull()
                t.column(CodingKeys.friday.rawValue, .integer).notNull()
                t.column(CodingKeys.saturday.rawValue, .integer).notNull()
                t.column(CodingKeys.sunday.rawValue, .integer).notNull()
            }
        }
    }
}
