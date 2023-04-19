//
//  AccountsManagerProtocol.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 19.04.2023.
//

import Foundation

protocol AccountsManagerProtocol {
    var accountsPublisher: Published<[Account]>.Publisher { get }
    func perform(operation: FinanceOperation) throws -> FinanceReceipt
    func resetUserData()
}
