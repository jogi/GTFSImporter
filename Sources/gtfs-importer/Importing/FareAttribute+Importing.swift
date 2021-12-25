//
//  FareAttribute+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB
import GTFSModel

extension FareAttribute: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "fare_attributes.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    public static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: FareAttribute.databaseTableName)
            } catch {
                print("Table \(FareAttribute.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: FareAttribute.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .text).notNull().primaryKey()
                t.column(CodingKeys.price.rawValue, .double).notNull()
                t.column(CodingKeys.currencyType.rawValue, .text).notNull()
                t.column(CodingKeys.paymentMethod.rawValue, .integer).notNull()
                t.column(CodingKeys.transfers.rawValue, .integer).notNull()
                t.column(CodingKeys.agencyIdentifier.rawValue, .text)
                t.column(CodingKeys.transferDuration.rawValue, .integer)
            }
        }
    }
}
