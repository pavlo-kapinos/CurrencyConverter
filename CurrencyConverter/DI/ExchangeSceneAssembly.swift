//
//  ExchangeSceneAssembly.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 19.04.2023.
//

import Swinject

class ExchangeSceneAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ExchangeViewController.self) { r in
            let viewModel = r.resolve(ExchangeViewModelProtocol.self)!
            let exchangeVC = ExchangeViewController(vm: viewModel)
            return exchangeVC
        }
     
        container.register(ExchangeViewModelProtocol.self) { r in
            ExchangeViewModel(accountsManager: r.resolve(AccountsManagerProtocol.self)!,
                              networkManager: r.resolve(NetworkManagerProtocol.self)!)
        }
        
        container.register(NetworkManagerProtocol.self) { _ in
            NetworkManager(config: .default)
        }
        
        container.register(AccountsManagerProtocol.self) { _ in
            AccountsManager(loadData: true)
        }
    }
}


