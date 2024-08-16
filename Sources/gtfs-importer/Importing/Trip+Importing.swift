//
//  Trip+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel
import OSLog

extension Trip: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "trips.txt"
    }
    
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let decoder = CSVRowDecoder()
            var record = try decoder.decode(Self.self, from: reader)
            record.wheelchairAccessible = record.wheelchairAccessible ?? .noInformation
            record.bikesAllowed = record.bikesAllowed ?? .noInformation
            try record.insert(db)
        } catch {
            Logger.importer.error("Error importing \(Self.self) - \(error)\n\(reader.currentRow ?? [])")
        }
    }
    
    // MARK:- DatabaseCreating
    public static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: Trip.databaseTableName)
            } catch {
                Logger.model.log("Table \(Trip.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: Trip.databaseTableName) { t in
                t.column(CodingKeys.identifier.rawValue, .text)
                    .notNull()
                    .primaryKey()
                t.column(CodingKeys.routeIdentifier.rawValue, .text)
                    .notNull()
                    .indexed()
                    .references(Route.databaseTableName)
                t.column(CodingKeys.serviceIdentifier.rawValue, .text)
                    .notNull()
                    .indexed()
                t.column(CodingKeys.headSign.rawValue, .text)
                t.column(CodingKeys.shortName.rawValue, .text)
                t.column(CodingKeys.directionIdentifier.rawValue, .integer)
                t.column(CodingKeys.blockIdentifier.rawValue, .text)
                t.column(CodingKeys.shapeIdentifier.rawValue, .text)
                t.column(CodingKeys.wheelchairAccessible.rawValue, .integer)
                    .notNull()
                t.column(CodingKeys.bikesAllowed.rawValue, .integer)
                    .notNull()
            }
        }
    }
}
