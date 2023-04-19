//
//  NetworkManagerProtocol.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 19.04.2023.
//

import Foundation

protocol NetworkManagerProtocol {
    func sendExchangeCurrencyRequest(amount: Decimal, source: Currency, destination: Currency,
                                     completion: @escaping (Result<CurrencyExchangeResponse, CustomError>) -> Void)
}
