//
//  Agency+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

extension Agency: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "agency.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: Agency.databaseTableName)
            } catch {
                print("Table \(Agency.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Agency.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .text).notNull().primaryKey()
                t.column(CodingKeys.name.rawValue, .text).notNull()
                t.column(CodingKeys.url.rawValue, .text).notNull()
                t.column(CodingKeys.timezone.rawValue, .text).notNull()
                t.column(CodingKeys.language.rawValue, .text)
                t.column(CodingKeys.phone.rawValue, .text)
                t.column(CodingKeys.fareURL.rawValue, .text)
                t.column(CodingKeys.email.rawValue, .text)
            }
        }
    }
}
