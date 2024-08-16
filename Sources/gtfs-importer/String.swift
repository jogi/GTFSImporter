//
//  String.swift
//  
//
//  Created by Vashishtha Jogi on 8/16/24.
//

import Foundation

extension String {
    var sanitizedTimeString: String {
        get {
            let originalComponents = self.components(separatedBy: ":")
            var hour = Int(originalComponents[0])!
            if hour >= 24 {
                hour = hour - 24
            }
            
            return "\(hour):\(originalComponents[1]):\(originalComponents[2])"
        }
    }
}
