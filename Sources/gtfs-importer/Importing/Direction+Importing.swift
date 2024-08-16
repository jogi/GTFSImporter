//
//  Direction+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GTFSModel

extension Direction: ImporterImporting {
    static var fileName: String {
        return "directions.txt"
    }
}
