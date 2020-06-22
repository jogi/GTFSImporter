//
//  FareRule.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

struct FareRule {
    var fareIdentifier: String
    var routeIdentifier: String?
    var originIdentifier: String?
    var destinationIdentifier: String?
    var containsIdentifier: String?
}

// For diffing
extension FareRule: Hashable {}

extension FareRule: Codable, PersistableRecord {
    static var databaseTableName = "fare_rules"
    
    private enum Columns {
        static let fareIdentifier = Column(CodingKeys.fareIdentifier)
        static let routeIdentifier = Column(CodingKeys.routeIdentifier)
        static let originIdentifier = Column(CodingKeys.originIdentifier)
        static let destinationIdentifier = Column(CodingKeys.destinationIdentifier)
        static let containsIdentifier = Column(CodingKeys.containsIdentifier)
    }
    
    enum CodingKeys: String, CodingKey {
        case fareIdentifier = "fare_id"
        case routeIdentifier = "route_id"
        case originIdentifier = "origin_id"
        case destinationIdentifier = "destination_id"
        case containsIdentifier = "contains_id"
    }
}

extension FareRule: CustomStringConvertible {
    var description: String {
        return "\(fareIdentifier): \(routeIdentifier ?? "")"
    }
}
