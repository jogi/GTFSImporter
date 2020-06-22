//
//  CalendarDates+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB

extension CalendarDate: ImporterImporting {
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
                try db.drop(table: CalendarDate.databaseTableName)
            } catch {
                print("Table \(CalendarDate.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: CalendarDate.databaseTableName) { t in
                t.column(CodingKeys.serviceIdentifier.rawValue, .text).notNull().indexed()
                t.column(CodingKeys.date.rawValue, .date).notNull()
                t.column(CodingKeys.exceptionType.rawValue, .integer).notNull()
            }
        }
    }
}
