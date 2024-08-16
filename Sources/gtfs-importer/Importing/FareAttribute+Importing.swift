//
//  FareAttribute+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GTFSModel

extension FareAttribute: ImporterImporting {
    static var fileName: String {
        return "fare_attributes.txt"
    }
}
