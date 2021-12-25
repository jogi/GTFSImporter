//
//  FareRule+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB
import GTFSModel

extension FareRule: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "fare_rules.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    public static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: FareRule.databaseTableName)
            } catch {
                print("Table \(FareRule.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: FareRule.databaseTableName) { t in
                t.column(CodingKeys.fareIdentifier.rawValue, .text).notNull()
                t.column(CodingKeys.routeIdentifier.rawValue, .text)
                t.column(CodingKeys.originIdentifier.rawValue, .text)
                t.column(CodingKeys.destinationIdentifier.rawValue, .text)
                t.column(CodingKeys.containsIdentifier.rawValue, .text)
            }
        }
    }
}
