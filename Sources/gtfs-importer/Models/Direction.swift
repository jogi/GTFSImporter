//
//  Direction.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

struct Direction {
    enum DirectionType: String, Codable {
        case north = "North"
        case south = "South"
        case east = "East"
        case west = "West"
        case northEast = "Northeast"
        case northWest = "Northwest"
        case southEast = "Southeast"
        case southWest = "Southwest"
        case clockwise = "Clockwise"
        case counterClockwise = "Counterclockwise"
        case inbound = "Inbound"
        case outbound = "Outbount"
        case loop = "Loop"
        case aLoop = "A Loop"
        case bLoop = "B Loop"
    }
    
    var identifier: Int
    var routeIdentifier: String
    var direction: DirectionType
    var name: String?
}

// For diffing
extension Direction: Hashable {}

extension Direction: Codable, PersistableRecord {
    static var databaseTableName = "directions"
    
    private enum Columns {
        static let identifier = Column(CodingKeys.identifier)
        static let routeIdentifier = Column(CodingKeys.routeIdentifier)
        static let direction = Column(CodingKeys.direction)
        static let name = Column(CodingKeys.name)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "direction_id"
        case routeIdentifier = "route_id"
        case direction
        case name = "direction_name"
    }
}

extension Direction: CustomStringConvertible {
    var description: String {
        return "\(routeIdentifier) : \(identifier) - \(name ?? "")"
    }
}
