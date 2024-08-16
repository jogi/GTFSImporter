//
//  FareRule+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GTFSModel

extension FareRule: ImporterImporting {
    static var fileName: String {
        return "fare_rules.txt"
    }
}
