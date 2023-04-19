//
//  DependencyProvider.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 19.04.2023.
//

import Swinject

class DependencyProvider {
    let assembler: Assembler
    let container = Container()
    
    init() {
        assembler = Assembler(
            [
                ExchangeSceneAssembly()
            ],
            container: container)
    }
}
