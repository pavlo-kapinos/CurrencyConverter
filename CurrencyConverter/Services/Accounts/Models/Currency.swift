//
//  Currency.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 02.04.2023.
//

import Foundation

enum Currency: String, CaseIterable, Codable {
    case EUR, USD, GBP, JPY
    
    var code: String { return self.rawValue }
    init?(codeString: String) {
        self.init(rawValue: codeString)
    }
}
