//
//  Route+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel

extension Route: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "routes.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let decoder = CSVRowDecoder()
            var record = try decoder.decode(Self.self, from: reader)
            record.color = record.color ?? "FFFFFF"
            record.textColor = record.textColor ?? "000000"
            record.sortOrder = record.sortOrder ?? 0
            record.continuousPickup = record.continuousPickup ?? .notContinuous
            record.continuousDropoff = record.continuousDropoff ?? .notContinuous
            try record.insert(db)
        }
    }
    
    // MARK:- DatabaseCreating
    public static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: Route.databaseTableName)
            } catch {
                print("Table \(Route.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Route.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .text).notNull().primaryKey()
                t.column(CodingKeys.type.rawValue, .integer).notNull()
                t.column(CodingKeys.agencyIdentifier.rawValue, .text)
                t.column(CodingKeys.shortName.rawValue, .text)
                t.column(CodingKeys.longName.rawValue, .text)
                t.column(CodingKeys.routeDescription.rawValue, .text)
                t.column(CodingKeys.url.rawValue, .text)
                t.column(CodingKeys.color.rawValue, .text).notNull()
                t.column(CodingKeys.textColor.rawValue, .text).notNull()
                t.column(CodingKeys.sortOrder.rawValue, .text).notNull()
                t.column(CodingKeys.continuousPickup.rawValue, .text).notNull()
                t.column(CodingKeys.continuousDropoff.rawValue, .text).notNull()
            }
        }
    }
}
