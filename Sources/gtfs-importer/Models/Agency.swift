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
    var language: String?
    var phone: String?
    var fareURL: URL?
    var email: String?
}

// For diffing
extension Agency: Hashable {}

extension Agency: Codable, PersistableRecord {
    private enum Columns {
        static let identifier = Column(CodingKeys.identifier)
        static let name = Column(CodingKeys.name)
        static let url = Column(CodingKeys.url)
        static let timezone = Column(CodingKeys.timezone)
        static let language = Column(CodingKeys.language)
        static let phone = Column(CodingKeys.phone)
        static let fareURL = Column(CodingKeys.fareURL)
        static let email = Column(CodingKeys.email)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "agency_id"
        case name = "agency_name"
        case url = "agency_url"
        case timezone = "agency_timezone"
        case language = "agency_lang"
        case phone = "agency_phone"
        case fareURL = "agency_fare_url"
        case email = "agency_email"
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
                t.column("agency_lang", .text)
                t.column("agency_phone", .text)
                t.column("agency_fare_url", .text)
                t.column("agency_email", .text)
            }
        }
    }
}

extension Agency: CustomStringConvertible {
    var description: String {
        return "\(identifier): \(name), \(url)"
    }
}
