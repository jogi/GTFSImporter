//
//  File.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
import CSV
import GRDB

struct Agency {
    var identifier: String
    var name: String
    var url: URL
    var timezone: String
}

// For diffing
extension Agency: Hashable {}

extension Agency: Codable, PersistableRecord {
    private enum Columns {
        static let identifier = Column(CodingKeys.identifier)
        static let name = Column(CodingKeys.name)
        static let url = Column(CodingKeys.url)
        static let timezone = Column(CodingKeys.timezone)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "agency_id"
        case name = "agency_name"
        case url = "agency_url"
        case timezone = "agency_timezone"
    }
}

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
                try db.drop(table: "agency")
            } catch {
                print("Table agency does not exist.")
            }
            
            // now create new table
            try db.create(table: "agency") { t in
                t.column("agency_id", .text).notNull().primaryKey()
                t.column("agency_name", .text).notNull()
                t.column("agency_url", .text).notNull()
                t.column("agency_timezone", .text).notNull()
            }
        }
    }
}

extension Agency: CustomStringConvertible {
    var description: String {
        return "\(identifier): \(name), \(url)"
    }
}
