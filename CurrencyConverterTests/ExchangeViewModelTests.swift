//
//  ExchangeViewModelTests.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 04.04.2023.
//

import XCTest

@testable import CurrencyConverter

final class ExchangeViewModelTests: XCTestCase {

    func testInitialModelState() {
        let vm = createVM()
        XCTAssertEqual(vm.state, .idle, "Start has to be from .idle state.")
    }
    
    func testSellCurrencyAmountSetting() {
        let vm = createVM()
        vm.setSellCurrencyAmount(value: 55.0)
        XCTAssertEqual(vm.sellAmount, 55.0, "After set, the model has wrong value.")
    }
    
    func testSellCurrencyTypeSetting() {
        let vm = createVM()
        vm.setSellCurrency(.USD)
        XCTAssertEqual(vm.sellCurrency, .USD, "After set, the model has wrong value.")
    }
    
    func testReceiveCurrencyTypeSetting() {
        let vm = createVM()
        vm.setReceiveCurrency(.USD)
        XCTAssertEqual(vm.receiveCurrency, .USD, "After set, the model has wrong value.")
    }
    
    func testSetTheSameCurrencyForSellAndReceive() {
        let vm = createVM()
        vm.setSellCurrency(.USD)
        vm.setReceiveCurrency(.USD)
        XCTAssertNotEqual(vm.sellCurrency, vm.receiveCurrency, "Has to be a logic to avoid that.")
    }
    
    func testCurrencyExchangeRateFetching() {
        let response = CurrencyExchangeResponse(amount: "55.55", currency: "USD")
        let vm = ExchangeViewModel(accountsManager: AccountsManager(),
                                   networkManager: StubNetworkManager(exchangeResponse: response))
        vm.setSellCurrency(.EUR)
        vm.setReceiveCurrency(.USD)
        vm.setSellCurrencyAmount(value: 20.00)
        vm.refreshReceiveAmount()
        XCTAssertEqual(vm.receiveAmount, 55.55, "Must be the same as in a response.")
        XCTAssertEqual(vm.receiveCurrency, .USD, "Must be the same as in a response.")
    }
    
    func testIntegrationOfGettingExchangeCurrencyReceiptAndValidateData() {
        let response = CurrencyExchangeResponse(amount: "44.44", currency: "USD")
        let vm = ExchangeViewModel(accountsManager: AccountsManager(balance: [.EUR: 15.00]),
                                   networkManager: StubNetworkManager(exchangeResponse: response))
        vm.setSellCurrency(.EUR)
        vm.setReceiveCurrency(.USD)
        vm.setSellCurrencyAmount(value: 15.00)
        vm.refreshReceiveAmount()
        let startExchangeDate = Date()
        let result = vm.makeExchange()
        let endExchangeDate = Date()
        if case .success(let receipt) = result, let operation = receipt.operation as? ExchangeCurrencyOperation {
            XCTAssertEqual(receipt.transactionNumber, 0, "The first transaction number is zero.")
            XCTAssertGreaterThanOrEqual(receipt.commissionFee, 0, "Commission Fee must have a positive value.")
            XCTAssertGreaterThanOrEqual(receipt.date, startExchangeDate, "Receipt date must be in start/end range.")
            XCTAssertLessThanOrEqual(receipt.date, endExchangeDate, "Receipt date must be in start/end range.")
            XCTAssertEqual(operation.sourceAmount, 15.0, "An operation data is not equal to model data.")
            XCTAssertEqual(operation.sourceCurrency, .EUR, "An operation data is not equal to model data.")
            XCTAssertEqual(operation.destinationAmount, 44.44, "An operation data is not equal to model data.")
            XCTAssertEqual(operation.destinationCurrency, .USD, "An operation data is not equal to model data.")
        } else {
            XCTFail("")
        }
    }
    
    private func createVM() -> ExchangeViewModel {
        return ExchangeViewModel(accountsManager: AccountsManager(),
                                 networkManager: StubNetworkManager())
    }
}
