//
//  AccountsMangerTests.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 04.04.2023.
//

import XCTest
@testable import CurrencyConverter

final class AccountsMangerTests: XCTestCase {
    
    func testInitialAccountsCreation() {
        let manager = AccountsManager()
        XCTAssertEqual(Currency.allCases.count, manager.accounts.count, "By one account for each currency.")
        
        let managerWithCustomBalance = AccountsManager(balance: [.EUR: 1000, .USD: 5000])
        XCTAssertEqual(Currency.allCases.count, managerWithCustomBalance.accounts.count, "By one account for each currency.")
        
        let managerWithLoadBalance = AccountsManager(loadData: true)
        XCTAssertEqual(Currency.allCases.count, managerWithLoadBalance.accounts.count, "By one account for each currency.")
    }
    
    func testExchangeOperationWithFee() throws {
        let manager = AccountsManager(balance: [.EUR: 1000, .USD: 5000])
        let exchange = ExchangeCurrencyOperation(sourceAmount: 100.0,
                                                 sourceCurrency: .EUR,
                                                 destinationAmount: 109.0,
                                                 destinationCurrency: .USD)
        let exchangeReceipt = try manager.perform(operation: exchange) as? ExchangeCurrencyReceipt
        let eurAccount = manager.accounts.first { $0.currency == .EUR }
        let usdAccount = manager.accounts.first { $0.currency == .USD }
        let receipt = try XCTUnwrap(exchangeReceipt)
        XCTAssertEqual(eurAccount?.amount, 900.0 - receipt.commissionFee, "Not expected balance after an exchange operation")
        XCTAssertEqual(usdAccount?.amount, 5109.0, "Not expected balance after an exchange operation")
    }
    
    func testFreeOfChargeOperations() throws {
        let manager = AccountsManager(balance: [.EUR: 1000, .USD: 5000])
        
        for _ in 0 ..< CommissionConstants.amountFirstFreeOfChargeTransaction {
            let exchange = ExchangeCurrencyOperation(sourceAmount: 10.0,
                                                     sourceCurrency: .EUR,
                                                     destinationAmount: 10.9,
                                                     destinationCurrency: .USD)
            let exchangeReceipt = try manager.perform(operation: exchange) as? ExchangeCurrencyReceipt
            let receipt = try XCTUnwrap(exchangeReceipt)
            XCTAssertEqual(receipt.commissionFee, 0, "There should be no commission fee here.")
        }
    }
    
    func testCommissionFeeAndTransactionAmount() throws {
        let manager = AccountsManager(balance: [.EUR: 1000, .USD: 5000])
        
        var commissionFeeSum: Decimal = 0
        var lastTransactionNumber: UInt = 0
        
        for _ in 0 ..< 100 {
            let exchange = ExchangeCurrencyOperation(sourceAmount: 1.0,
                                                     sourceCurrency: .EUR,
                                                     destinationAmount: 1.09,
                                                     destinationCurrency: .USD)
            let exchangeReceipt = try manager.perform(operation: exchange) as? ExchangeCurrencyReceipt
            let receipt = try XCTUnwrap(exchangeReceipt)
            commissionFeeSum += receipt.commissionFee
            lastTransactionNumber = receipt.transactionNumber
        }
        let multiplier = CommissionConstants.chargePercentOnTransaction / 100.0
        XCTAssertEqual(commissionFeeSum, Decimal(100 - CommissionConstants.amountFirstFreeOfChargeTransaction) * multiplier,
                       "The accumulated commission fee after 100 transactions has to be equal to the amount calculated by the formula.")
        XCTAssertEqual(lastTransactionNumber, 99, "Transaction number in the last receipt has to be 99.")
    }
    
    func testLoadDataFromThePreviousSession() throws {
        let manager = AccountsManager(balance: [.EUR: 1000, .USD: 5000])
        let eurAccount = manager.accounts.first { $0.currency == .EUR }
        // next session
        let newManager = AccountsManager(loadData: true)
        let eurAccount1 = newManager.accounts.first { $0.currency == .EUR }
        let usdAccount1 = newManager.accounts.first { $0.currency == .USD }
        
        XCTAssertEqual(eurAccount!.id, eurAccount1!.id, "Account 'id' has changed between sessions.")
        XCTAssertEqual(eurAccount1!.amount, 1000, "Amount of EUR has changed between sessions.")
        XCTAssertEqual(usdAccount1!.amount, 5000, "Amount of EUR has changed between sessions.")
    }
    
    func testExchangeOfTheSameCurrencyError() {
        let manager = AccountsManager(balance: [.EUR: 1000])
        let exchange = ExchangeCurrencyOperation(sourceAmount: 100.0,
                                                 sourceCurrency: .EUR,
                                                 destinationAmount: 109.0,
                                                 destinationCurrency: .EUR)
        XCTAssertThrowsError(try manager.perform(operation: exchange), "Expected error: ExchangeCurrencyError.theSameCurrency")
    }
    
}
