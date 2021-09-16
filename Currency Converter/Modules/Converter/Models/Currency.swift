//
//  Currency.swift
//  Currency Converter
//
//  Created by Abdurrahman on 15/09/2021.
//

import Foundation

struct Currency: Codable {
    var amount: String
    var currency: Currencies
    
    init(amount: String, currency: Currencies) {
        self.amount = amount
        self.currency = currency
    }
}
