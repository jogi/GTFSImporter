//
//  Database.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
import GRDB

protocol DatabaseCreating {
    static func createTable() throws
}

struct DatabaseHelper {
    var dbQueue: DatabaseQueue?
    
    init() throws {
        dbQueue = try DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    func vacuum() throws {
        try dbQueue?.vacuum()
    }
    
    func reindex() throws {
        try dbQueue?.writeWithoutTransaction { try $0.execute(sql: "REINDEX") }
    }
}
