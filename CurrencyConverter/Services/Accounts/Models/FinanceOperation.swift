//
//  FinanceOperation.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 02.04.2023.
//

import Foundation

protocol FinanceOperation {
    var name: String { get }
}

struct UnknownOperation: FinanceOperation {
    let name = "Unknown Operation"
}

struct ExchangeCurrencyOperation: FinanceOperation {
    let name = "Exchange Currency"
    let sourceAmount: Decimal
    let sourceCurrency: Currency
    let destinationAmount: Decimal
    let destinationCurrency: Currency
}
