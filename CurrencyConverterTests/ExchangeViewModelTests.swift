//
//  ExchangeViewModelTests.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 04.04.2023.
//

import XCTest

@testable import CurrencyConverter

final class ExchangeViewModelTests: XCTestCase {

    var sut: ExchangeViewModel!
    
    override func setUp() async throws {
        continueAfterFailure = false
        sut = ExchangeViewModel(accountsManager: AccountsManager(), networkManager: StubNetworkManager())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testInitialModelState() {
        XCTAssertEqual(sut.state, .idle, "Start has to be from .idle state.")
    }
    
    func testSellCurrencyAmountSetting() {
        let sellAmount: Decimal = 55.0
        sut.setSellCurrencyAmount(value: sellAmount)
        XCTAssertEqual(sut.sellAmount, sellAmount, "After set, the model has wrong value.")
    }
    
    func testSellCurrencyTypeSetting() {
        let currency: Currency = .USD
        sut.setSellCurrency(currency)
        XCTAssertEqual(sut.sellCurrency, .USD, "After set, the model has wrong value.")
    }
    
    func testReceiveCurrencyTypeSetting() {
        let currency: Currency = .USD
        sut.setReceiveCurrency(currency)
        XCTAssertEqual(sut.receiveCurrency, currency, "After set, the model has wrong value.")
    }
    
    func testSetTheSameCurrencyForSellAndReceive() {
        let currency: Currency = .USD
        
        sut.setSellCurrency(currency)
        sut.setReceiveCurrency(currency)
        
        XCTAssertNotEqual(sut.sellCurrency, sut.receiveCurrency, "Has to be a logic to avoid that.")
    }
    
    func testCurrencyExchangeRateFetching() {
        let response = CurrencyExchangeResponse(amount: "55.55", currency: "USD")
        let sellAmount: Decimal = 20.0 // can be any number, but more than zero
        let expectedAmount: Decimal = 55.55 // equal to response
        let expectedCurrency = Currency.USD // equal to response
        
        let vm = ExchangeViewModel(accountsManager: AccountsManager(), networkManager: StubNetworkManager(exchangeResponse: response))
        vm.setSellCurrency(.EUR)
        vm.setReceiveCurrency(.USD)
        vm.setSellCurrencyAmount(value: sellAmount)
        vm.refreshReceiveAmount()
        
        XCTAssertEqual(vm.receiveAmount, expectedAmount, "Must be the same as in a response.")
        XCTAssertEqual(vm.receiveCurrency, expectedCurrency, "Must be the same as in a response.")
    }
    
    func testIntegrationOfGettingExchangeCurrencyReceiptAndValidateData() {
        let response = CurrencyExchangeResponse(amount: "44.44", currency: "USD")
        let receiveAmount: Decimal = 44.44
        let sellAmount: Decimal = 15.0
        let sellCurrency: Currency = .EUR
        let receiveCurrency: Currency = .USD
        let vm = ExchangeViewModel(accountsManager: AccountsManager(balance: [.EUR: sellAmount]),
                                   networkManager: StubNetworkManager(exchangeResponse: response))

        vm.setSellCurrency(sellCurrency)
        vm.setReceiveCurrency(receiveCurrency)
        vm.setSellCurrencyAmount(value: sellAmount)
        vm.refreshReceiveAmount()
        let startExchangeDate = Date()
        let result = vm.makeExchange()
        let endExchangeDate = Date()
        
        if case .success(let receipt) = result, let operation = receipt.operation as? ExchangeCurrencyOperation {
            XCTAssertEqual(receipt.transactionNumber, 0, "The first transaction number is zero.")
            XCTAssertGreaterThanOrEqual(receipt.commissionFee, 0, "Commission Fee must have a positive value.")
            XCTAssertGreaterThanOrEqual(receipt.date, startExchangeDate, "Receipt date must be in start/end range.")
            XCTAssertLessThanOrEqual(receipt.date, endExchangeDate, "Receipt date must be in start/end range.")
            XCTAssertEqual(operation.sourceAmount, sellAmount, "An operation data is not equal to model data.")
            XCTAssertEqual(operation.sourceCurrency, sellCurrency, "An operation data is not equal to model data.")
            XCTAssertEqual(operation.destinationAmount, receiveAmount, "An operation data is not equal to model data.")
            XCTAssertEqual(operation.destinationCurrency, receiveCurrency, "An operation data is not equal to model data.")
        } else {
            XCTFail("")
        }
    }
}
