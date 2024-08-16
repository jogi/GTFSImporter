//
//  Logger.swift
//
//
//  Created by Vashishtha Jogi on 8/11/24.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = "com.jogi.gtfs-importer"

    static let importer = Logger(subsystem: subsystem, category: "importer")
}
