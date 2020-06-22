//
//  Stop+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

extension Stop: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "stops.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: Stop.databaseTableName)
            } catch {
                print("Table \(Stop.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Stop.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .text).notNull().primaryKey()
                t.column(CodingKeys.code.rawValue, .text)
                t.column(CodingKeys.name.rawValue, .text)
                t.column(CodingKeys.stopDescription.rawValue, .text)
                t.column(CodingKeys.latitude.rawValue, .double).notNull().indexed()
                t.column(CodingKeys.longitude.rawValue, .double).notNull().indexed()
                t.column(CodingKeys.zoneIdentifier.rawValue, .text)
                t.column(CodingKeys.locationType.rawValue, .integer).notNull()
                t.column(CodingKeys.parentStation.rawValue, .text)
                t.column(CodingKeys.timezone.rawValue, .text)
                t.column(CodingKeys.wheelchairBording.rawValue, .integer).notNull()
                t.column(CodingKeys.levelIdentifier.rawValue, .text)
                t.column(CodingKeys.platformCode.rawValue, .text)
            }
        }
    }
}
