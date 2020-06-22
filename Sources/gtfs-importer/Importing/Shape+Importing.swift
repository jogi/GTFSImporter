//
//  Shape+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

extension Shape: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "shapes.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: Shape.databaseTableName)
            } catch {
                print("Table \(Shape.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Shape.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .text).notNull().indexed()
                t.column(CodingKeys.latitude.rawValue, .double).notNull()
                t.column(CodingKeys.longitude.rawValue, .double).notNull()
                t.column(CodingKeys.sequence.rawValue, .integer).notNull()
                t.column(CodingKeys.distanceTraveled.rawValue, .double)
            }
        }
    }
}
