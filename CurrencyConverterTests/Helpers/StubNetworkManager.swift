//
//  StubNetworkManager.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 03.04.2023.
//

import Foundation

@testable import CurrencyConverter
class StubNetworkManager: NetworkManager {
    
    private var exchangeResponse = CurrencyExchangeResponse(amount: "555.0", currency: "EUR")
    
    init() {
        super.init(config: .debug)
    }
    
    init(exchangeResponse: CurrencyExchangeResponse) {
        self.exchangeResponse = exchangeResponse
        super.init(config: .debug)
    }
    
    override func sendExchangeCurrencyRequest(amount: Decimal, source: Currency, destination: Currency, completion: @escaping (Result<CurrencyExchangeResponse, CustomError>) -> Void) {
        completion(.success(exchangeResponse))
    }
}
