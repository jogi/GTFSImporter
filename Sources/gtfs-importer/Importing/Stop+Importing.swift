//
//  Stop+Importing.swift
//
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GTFSModel

extension Stop: ImporterImporting {
    static var fileName: String {
        return "stops.txt"
    }
}
