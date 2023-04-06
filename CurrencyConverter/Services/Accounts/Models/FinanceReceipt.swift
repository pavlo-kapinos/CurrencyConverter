//
//  FinanceReceipt.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 02.04.2023.
//

import Foundation

protocol FinanceReceipt {
    var date: Date { get }
    var operation: FinanceOperation { get }
}

struct EmptyReceipt: FinanceReceipt {
    let date = Date()
    var operation: FinanceOperation = UnknownOperation()
}

struct ExchangeCurrencyReceipt: FinanceReceipt {
    let date = Date()
    let operation: FinanceOperation
    let commissionFee: Decimal
    let transactionNumber: UInt
}
