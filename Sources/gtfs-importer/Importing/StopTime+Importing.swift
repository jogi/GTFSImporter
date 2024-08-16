//
//  StopTime+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel
import OSLog

extension StopTime: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "stop_times.txt"
    }
    
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let decoder = CSVRowDecoder()
            decoder.dateDecodingStrategy = .custom({ value in
                let sanitizedValue = value.sanitizedTimeString
                
                guard let date = DateFormatter.hhmmss.date(from: sanitizedValue) else {
                    throw ImporterError.invalidTime(time: "value: \(value) sanitizedValue: \(sanitizedValue)")
                }
                
                return date
            })
            var record = try decoder.decode(Self.self, from: reader)
            
            record.pickupType = record.pickupType ?? .regularlyScheduled
            record.dropoffType = record.dropoffType ?? .regularlyScheduled
            record.continuousPickup = record.continuousPickup ?? .notContinuous
            record.continuousDropoff = record.continuousDropoff ?? .notContinuous
            record.timepoint = record.timepoint ?? .exact
            try record.insert(db)
        } catch {
            Logger.importer.error("Error importing \(Self.self) - \(error)\n\(reader.currentRow ?? [])")
        }
    }
    
    // MARK:- DatabaseCreating
    public static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: StopTime.databaseTableName)
            } catch {
                Logger.model.log("Table \(StopTime.databaseTableName) does not exist.")
            }
            
            // now create new table
            try db.create(table: StopTime.databaseTableName) { t in
                t.column(CodingKeys.tripIdentifier.rawValue, .text)
                    .notNull()
                    .indexed()
                    .references(Trip.databaseTableName)
                t.column(CodingKeys.arrivalTime.rawValue, Database.ColumnType(rawValue: "TIME")).notNull()
                t.column(CodingKeys.departureTime.rawValue, Database.ColumnType(rawValue: "TIME")).notNull()
                t.column(CodingKeys.stopIdentifier.rawValue, .text)
                    .notNull()
                    .indexed()
                    .references(Stop.databaseTableName)
                t.column(CodingKeys.stopSequence.rawValue, .integer).notNull()
                t.column(CodingKeys.stopHeadsign.rawValue, .text)
                t.column(CodingKeys.pickupType.rawValue, .integer).notNull()
                t.column(CodingKeys.dropoffType.rawValue, .integer).notNull()
                t.column(CodingKeys.continuousPickup.rawValue, .integer).notNull()
                t.column(CodingKeys.continuousDropoff.rawValue, .integer).notNull()
                t.column(CodingKeys.shapeDistanceTraveled.rawValue, .double)
                t.column(CodingKeys.timepoint.rawValue, .integer).notNull()
            }
        }
    }
}
