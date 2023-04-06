//
//  NetworkConfig.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 31.03.2023.
//

import Foundation

struct NetworkConfig {
    static let `default` = NetworkConfig(host: "http://api.evp.lt")
    static let debug     = NetworkConfig(host: "http://test.api.evp.lt")
    
    let host: String
    
    let exchangeCurrencyRequestPath = "/currency/commercial/exchange/%@-%@/%@/latest"
}
