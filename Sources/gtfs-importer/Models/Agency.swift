//
//  Agency.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
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

extension Agency: CustomStringConvertible {
    var description: String {
        return "\(identifier): \(name), \(url)"
    }
}
