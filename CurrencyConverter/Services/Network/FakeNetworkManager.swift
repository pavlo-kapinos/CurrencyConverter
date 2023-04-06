//
//  LocalNetworkManager.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 31.03.2023.
//

import Foundation

class FakeNetworkManager: NetworkManager {
    override func sendExchangeCurrencyRequest(amount: Decimal, source: Currency, destination: Currency, completion: @escaping (Result<CurrencyExchangeResponse, CustomError>) -> Void) {
        guard amount > 0 else {
            completion(.failure(.invalidParams))
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let convertedAmount = (self.rate(destination) * amount) / self.rate(source)
            completion(.success(CurrencyExchangeResponse(amount: "\(convertedAmount)", currency: "USD")))
        }
    }
    
    private func rate(_ currency: Currency) -> Decimal {
        switch currency {
        case .EUR: return 1.0
        case .USD: return 1.09
        case .GBP: return 0.87
        case .JPY: return 144
        }
    }
}

