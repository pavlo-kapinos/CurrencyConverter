//
//  NetworkManager.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 31.03.2023.
//

import Foundation

enum CustomError: Error {
    case wrongURL
    case parsingError
    case serverError(Error)
    case invalidParams
}

struct CurrencyExchangeResponse: Decodable {
    let amount, currency: String
}

class NetworkManager {
    let config: NetworkConfig
    
    init(config: NetworkConfig) {
        self.config = config
    }
    
    func sendExchangeCurrencyRequest(amount: Decimal, source: Currency, destination: Currency, completion: @escaping (Result<CurrencyExchangeResponse, CustomError>) -> Void) {
        guard amount > 0.0 else {
            completion(.failure(.invalidParams))
            return
        }
        
        let requestPath = String(format: config.exchangeCurrencyRequestPath, String(describing: amount), source.code, destination.code)
        guard let url = URL(string: config.host + requestPath) else {
            completion(.failure(.wrongURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {(jsonData, response, error) in
            if let jsonData,
               let response = try? JSONDecoder().decode(CurrencyExchangeResponse.self, from: jsonData) {
                completion(.success(response))
            } else {
                if let error {
                    completion(.failure(.serverError(error)))
                } else {
                    completion(.failure(.parsingError))
                }
            }
        }
        task.resume()
    }
}
