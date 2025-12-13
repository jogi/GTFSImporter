//
//  DatabaseHelper.swift
//
//
//  Created by Claude Code on 12/12/25.
//

import Foundation
import GRDB
import OSLog

struct DatabaseHelper {
    let dbQueue: DatabaseQueue

    init(path: String) throws {
        var configuration = Configuration()
        configuration.publicStatementArguments = true
        self.dbQueue = try DatabaseQueue(path: path, configuration: configuration)
    }

    func vacuum() throws {
        try dbQueue.inDatabase { db in
            try db.execute(sql: "VACUUM")
        }
    }

    func reindex() throws {
        try dbQueue.inDatabase { db in
            try db.execute(sql: "REINDEX")
        }
    }

    func interpolateStopTimes() throws {
        try dbQueue.write { db in
            try StopTimeInterpolator.interpolateStopTimes(in: db)
        }
    }
}
