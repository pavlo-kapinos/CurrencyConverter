//
//  ExchangeViewControllerTests.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 03.04.2023.
//

import XCTest
@testable import CurrencyConverter

final class ExchangeViewControllerTests: XCTestCase {

    func test_ViewIsLoadedAndOutletsAreConnected() {
        let vc = createExchangeVC()
        vc.loadViewIfNeeded()
        XCTAssertNotNil(vc.accountsCollectionView, "Outlet is not connected.")
        XCTAssertNotNil(vc.sellAmountTextField, "Outlet is not connected.")
        XCTAssertNotNil(vc.sellCurrencyButton, "Outlet is not connected.")
        XCTAssertNotNil(vc.receiveAmountTextField, "Outlet is not connected.")
        XCTAssertNotNil(vc.receiveCurrencyButton, "Outlet is not connected.")
        XCTAssertNotNil(vc.submitButton, "Outlet is not connected.")
    }

    func test_ViewDidLoad_Title() {
        let vc = createExchangeVC()
        vc.loadViewIfNeeded()
        XCTAssertEqual(vc.title, "Currency Converter", "App's title has changed.")
    }
    
    func test_ViewDidLoad_SellAmountConfigure() {
        let vc = createExchangeVC()
        vc.loadViewIfNeeded()
        XCTAssertNotNil(vc.sellAmountTextField.delegate, "Has to be connected to correction logic.")
    }
    
    func test_ViewDidLoad_SellAmountAndReceiveAmountAreEmpty() {
        let vc = createExchangeVC()
        vc.loadViewIfNeeded()
        XCTAssertEqual(vc.sellAmountTextField.text, "", "Has to be empty on start.")
        XCTAssertEqual(vc.receiveAmountTextField.text, "", "Has to be empty on start.")
    }

    private func createExchangeVC() -> ExchangeViewController {
        return ExchangeViewController(networkManager: StubNetworkManager(),
                                      accountsManager: AccountsManager())
    }
}
