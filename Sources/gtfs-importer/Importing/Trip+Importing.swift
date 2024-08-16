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
}
