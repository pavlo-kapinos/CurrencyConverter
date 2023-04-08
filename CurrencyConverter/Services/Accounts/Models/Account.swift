//
//  Account.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 02.04.2023.
//

import Foundation

struct Account: Codable, Equatable {
    let id: String
    let currency: Currency
    var amount: Decimal
}
