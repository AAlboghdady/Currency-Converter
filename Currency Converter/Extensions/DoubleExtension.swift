//
//  DoubleExtension.swift
//  Currency Converter
//
//  Created by Abdurrahman on 16/09/2021.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func rounded(to places:Int) -> String {
        return String(format: "%.\(places)f", self)
    }
}
