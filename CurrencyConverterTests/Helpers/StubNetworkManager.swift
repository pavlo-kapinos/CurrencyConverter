//
//  StubNetworkManager.swift
//  CurrencyConverterTests
//
//  Created by Pavlo Kapinos on 03.04.2023.
//

import Foundation

@testable import CurrencyConverter
class StubNetworkManager: NetworkManagerProtocol {
    
    private var exchangeResponse: CurrencyExchangeResponse
    
    init() {
        exchangeResponse = CurrencyExchangeResponse(amount: "555.0", currency: "EUR")
    }
    
    init(exchangeResponse: CurrencyExchangeResponse) {
        self.exchangeResponse = exchangeResponse
    }
    
    func sendExchangeCurrencyRequest(amount: Decimal, source: Currency, destination: Currency, completion: @escaping (Result<CurrencyExchangeResponse, CustomError>) -> Void) {
        completion(.success(exchangeResponse))
    }
}
