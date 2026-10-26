//
//  Trip+Importing.swift
//
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import CSV
import Foundation
import GRDB
import GTFSModel
import OSLog

extension Trip: ImporterImporting {
    static var fileName: String {
        return "trips.txt"
    }

    @discardableResult
    static func receiveImport(from reader: CSVReader, with db: Database) throws -> Bool {
        do {
            var record = try CSVRowDecoder.shared.decode(Self.self, from: reader)
            record.wheelchairAccessible = record.wheelchairAccessible ?? .noInformation
            record.bikesAllowed = record.bikesAllowed ?? .noInformation
            try record.insert(db)
            return true
        } catch {
            ImportDiagnostics.rejected(Self.self, error: error, row: reader.currentRow)
            return false
        }
    }
}
