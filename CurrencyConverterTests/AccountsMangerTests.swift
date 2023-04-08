//
//  AccountsMangerTests.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 04.04.2023.
//

import XCTest
@testable import CurrencyConverter

final class AccountsMangerTests: XCTestCase {
    
    let rateEurToUsd: Decimal = 1.09
    var sut: AccountsManager!
    
    override func setUp() {
        continueAfterFailure = false
        sut = AccountsManager(balance: [.EUR: 1000, .USD: 5000])
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testInitialAccountsCreation() {
        XCTAssertEqual(Currency.allCases.count, sut.accounts.count, "By one account for each currency.")
        XCTAssertEqual(Currency.allCases.count, sut.accounts.count, "By one account for each currency.")
        
        let managerWithLoadBalance = AccountsManager(loadData: true)
        XCTAssertEqual(Currency.allCases.count, managerWithLoadBalance.accounts.count, "By one account for each currency.")
    }
    
    func testExchangeOperationWithFee() throws {
        let sellAmount = sut.getAmountForCurrency(.EUR)
        let receiveAmount = sellAmount * rateEurToUsd
        
        let eurAmountOnStart = sut.getAmountForCurrency(.EUR)
        let usdAmountOnStart = sut.getAmountForCurrency(.USD)
        let exchange = ExchangeCurrencyOperation(sourceAmount: sellAmount,
                                                 sourceCurrency: .EUR,
                                                 destinationAmount: receiveAmount,
                                                 destinationCurrency: .USD)
        let exchangeReceipt = try sut.perform(operation: exchange) as? ExchangeCurrencyReceipt
        let eurAmount = sut.getAmountForCurrency(.EUR)
        let usdAmount = sut.getAmountForCurrency(.USD)
        
        let receipt = try XCTUnwrap(exchangeReceipt)
        XCTAssertEqual(eurAmount, eurAmountOnStart - sellAmount - receipt.commissionFee, "Not expected balance after an exchange operation")
        XCTAssertEqual(usdAmount, usdAmountOnStart + receiveAmount, "Not expected balance after an exchange operation")
    }
    
    func testFreeOfChargeOperations() throws {
        let sellAmount = sut.getAmountForCurrency(.EUR) / Decimal(CommissionConstants.amountFirstFreeOfChargeTransaction)
        
        for _ in 0 ..< CommissionConstants.amountFirstFreeOfChargeTransaction {
            let exchange = ExchangeCurrencyOperation(sourceAmount: sellAmount,
                                                     sourceCurrency: .EUR,
                                                     destinationAmount: sellAmount * rateEurToUsd,
                                                     destinationCurrency: .USD)
            let exchangeReceipt = try sut.perform(operation: exchange) as? ExchangeCurrencyReceipt
            let receipt = try XCTUnwrap(exchangeReceipt)
            XCTAssertEqual(receipt.commissionFee, 0, "There should be no commission fee here.")
        }
    }
    
    func testCommissionFeeAndTransactionAmount() throws {
        let transactionsCount = CommissionConstants.amountFirstFreeOfChargeTransaction * UInt(10) // make 10x transactions
        let sellAmount = (sut.getAmountForCurrency(.EUR) / Decimal(transactionsCount)) / 2 // divide by 2 to include a commission fee
        var commissionFeeSum: Decimal = 0
        var lastTransactionNumber: UInt = 0
        
        for _ in 0 ..< transactionsCount {
            let exchange = ExchangeCurrencyOperation(sourceAmount: sellAmount,
                                                     sourceCurrency: .EUR,
                                                     destinationAmount: sellAmount * rateEurToUsd,
                                                     destinationCurrency: .USD)
            let exchangeReceipt = try sut.perform(operation: exchange) as? ExchangeCurrencyReceipt
            let receipt = try XCTUnwrap(exchangeReceipt)
            commissionFeeSum += receipt.commissionFee
            lastTransactionNumber = receipt.transactionNumber
        }
        let multiplier = CommissionConstants.chargePercentOnTransaction / 100
        XCTAssertEqual(commissionFeeSum, Decimal(transactionsCount - CommissionConstants.amountFirstFreeOfChargeTransaction) * sellAmount * multiplier,
                       "The accumulated commission fee after 100 transactions has to be equal to the amount calculated by the formula.")
        XCTAssertEqual(lastTransactionNumber, transactionsCount - 1, "Transaction number in the last receipt has to be 99.")
    }
    
    func testEqualityOfAccountsBetweenSession() throws {
        let accounts = sut.accounts
        // next session
        let newManager = AccountsManager(loadData: true)
        XCTAssertEqual(accounts, newManager.accounts, "The accounts has changed between sessions.")
    }
    
    func testExchangeOfTheSameCurrencyError() {
        let sellAmount = sut.getAmountForCurrency(.EUR)
        
        let exchange = ExchangeCurrencyOperation(sourceAmount: sellAmount,
                                                 sourceCurrency: .EUR,
                                                 destinationAmount: sellAmount * rateEurToUsd,
                                                 destinationCurrency: .EUR)
        XCTAssertThrowsError(try sut.perform(operation: exchange), "Expected error: ExchangeCurrencyError.theSameCurrency")
    }
}
