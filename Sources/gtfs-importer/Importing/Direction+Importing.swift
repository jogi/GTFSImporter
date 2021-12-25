//
//  Direction+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB
import GTFSModel

extension Direction: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "directions.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    public static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: Direction.databaseTableName)
            } catch {
                print("Table \(Direction.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Direction.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .integer).notNull()
                t.column(CodingKeys.routeIdentifier.rawValue, .text).notNull()
                t.column(CodingKeys.direction.rawValue, .text).notNull()
                t.column(CodingKeys.name.rawValue, .text)
                t.primaryKey([CodingKeys.identifier.rawValue, CodingKeys.routeIdentifier.rawValue])
            }
        }
    }
}
