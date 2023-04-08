//
//  ExchangeViewControllerTests.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 03.04.2023.
//

import XCTest
@testable import CurrencyConverter

final class ExchangeViewControllerTests: XCTestCase {

    var sut: ExchangeViewController!
    
    override func setUp() {
        continueAfterFailure = false
        sut = ExchangeViewController(networkManager: StubNetworkManager(),
                                     accountsManager: AccountsManager())
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func test_ViewIsLoadedAndOutletsAreConnected() {
        XCTAssertNotNil(sut.accountsCollectionView, "Outlet is not connected.")
        XCTAssertNotNil(sut.sellAmountTextField, "Outlet is not connected.")
        XCTAssertNotNil(sut.sellCurrencyButton, "Outlet is not connected.")
        XCTAssertNotNil(sut.receiveAmountTextField, "Outlet is not connected.")
        XCTAssertNotNil(sut.receiveCurrencyButton, "Outlet is not connected.")
        XCTAssertNotNil(sut.submitButton, "Outlet is not connected.")
    }

    func test_ViewDidLoad_Title() {
        XCTAssertEqual(sut.title, "Currency Converter", "App's title has changed.")
    }
    
    func test_ViewDidLoad_SellAmountConfigure() {
        XCTAssertNotNil(sut.sellAmountTextField.delegate, "Has to be connected to correction logic.")
    }
    
    func test_ViewDidLoad_SellAmountAndReceiveAmountAreEmpty() {
        XCTAssertEqual(sut.sellAmountTextField.text, "", "Has to be empty on start.")
        XCTAssertEqual(sut.receiveAmountTextField.text, "", "Has to be empty on start.")
    }
}
