//
//  Route.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

struct Route {
    /*
     0 - Tram, Streetcar, Light rail. Any light rail or street level system within a metropolitan area.
     1 - Subway, Metro. Any underground rail system within a metropolitan area.
     2 - Rail. Used for intercity or long-distance travel.
     3 - Bus. Used for short- and long-distance bus routes.
     4 - Ferry. Used for short- and long-distance boat service.
     5 - Cable tram. Used for street-level rail cars where the cable runs beneath the vehicle, e.g., cable car in San Francisco.
     6 - Aerial lift, suspended cable car (e.g., gondola lift, aerial tramway). Cable transport where cabins, cars, gondolas or open chairs are suspended by means of one or more cables.
     7 - Funicular. Any rail system designed for steep inclines.
     11 - Trolleybus. Electric buses that draw power from overhead wires using poles.
     12 - Monorail. Railway in which the track consists of a single rail or a beam.
     */
    enum RouteType: Int, Codable {
        case tram = 0
        case subway = 1
        case rail = 2
        case bus = 3
        case ferry = 4
        case cableTram = 5
        case aerialLift = 6
        case funicular = 7
        case trolleyBus = 11
        case monorail = 12
    }
    
    enum ContinuationType: Int, Codable {
        case continuous = 0
        case notContinuous = 1
        case phoneAgencyToArrange = 2
        case coordinateWithDriver = 3
    }
    
    var identifier: String
    var type: RouteType
    var agencyIdentifier: String?
    var shortName: String?
    var longName: String?
    var routeDescription: String?
    var url: URL?
    var color: String? = "FFFFFF"
    var textColor: String? = "000000"
    var sortOrder: Int?
    var continuousPickup: ContinuationType?
    var continuousDropoff: ContinuationType?
}

// For diffing
extension Route: Hashable {}

extension Route: Codable, PersistableRecord {
    static var databaseTableName = "routes"
    
    private enum Columns {
        static let identifier = Column(CodingKeys.identifier)
        static let type = Column(CodingKeys.type)
        static let agencyIdentifier = Column(CodingKeys.agencyIdentifier)
        static let shortName = Column(CodingKeys.shortName)
        static let longName = Column(CodingKeys.longName)
        static let routeDescription = Column(CodingKeys.routeDescription)
        static let url = Column(CodingKeys.url)
        static let color = Column(CodingKeys.color)
        static let textColor = Column(CodingKeys.textColor)
        static let sortOrder = Column(CodingKeys.sortOrder)
        static let continuousPickup = Column(CodingKeys.continuousPickup)
        static let continuousDropoff = Column(CodingKeys.continuousDropoff)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "route_id"
        case type = "route_type"
        case agencyIdentifier = "agency_id"
        case shortName = "route_short_name"
        case longName = "route_long_name"
        case routeDescription = "route_desc"
        case url = "route_url"
        case color = "route_color"
        case textColor = "route_text_color"
        case sortOrder = "route_sort_order"
        case continuousPickup = "continuous_pickup"
        case continuousDropoff = "continuous_drop_off"
    }
}

extension Route: CustomStringConvertible {
    var description: String {
        return "\(identifier): \(type), \(shortName ?? ""), \(longName ?? "")"
    }
}
