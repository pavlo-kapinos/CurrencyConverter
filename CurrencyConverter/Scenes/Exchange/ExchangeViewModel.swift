//
//  ExchangeViewModel.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import Foundation
import Combine

class ExchangeViewModel: ExchangeViewModelProtocol {
    enum State {
        case idle, fetching, error
    }

    @Published var state: State = .idle
    
    @Published private(set) var sellAmount: Decimal = 0
    @Published private(set) var sellCurrency: Currency = .EUR
    @Published private(set) var receiveCurrency: Currency = .USD
    @Published private(set) var receiveAmount: Decimal?

    var accountsPublisher: Published<[Account]>.Publisher { accountsManager.accountsPublisher }
    var statePublisher: Published<State>.Publisher { $state }
    var sellCurrencyPublisher: Published<Currency>.Publisher { $sellCurrency }
    var receiveCurrencyPublisher: Published<Currency>.Publisher { $receiveCurrency }
    var receiveAmountPublisher: Published<Decimal?>.Publisher { $receiveAmount }

    var fetchReceiveTimer: AnyCancellable?

    let networkManager: NetworkManagerProtocol
    let accountsManager: AccountsManagerProtocol
    var availableCurrencies: [Currency] { return Currency.allCases.sorted { $0.code < $1.code } }
    
    init(accountsManager: AccountsManagerProtocol, networkManager: NetworkManagerProtocol) {
        self.accountsManager = accountsManager
        self.networkManager = networkManager
    }
    
    func makeExchange() -> Result<ExchangeCurrencyReceipt, ExchangeCurrencyError> {
        guard let receiveAmount else {
            return .failure(.noReceiveAmount)
        }
        
        let exchangeOperation = ExchangeCurrencyOperation(sourceAmount: sellAmount,
                                                          sourceCurrency: sellCurrency,
                                                          destinationAmount: receiveAmount,
                                                          destinationCurrency: receiveCurrency)
        do {
            if let receipt = try accountsManager.perform(operation: exchangeOperation) as? ExchangeCurrencyReceipt {
                return .success(receipt)
            } else {
                return .failure(.internal)
            }
        } catch {
            return .failure(error as? ExchangeCurrencyError ?? .internal)
        }
    }

    func setSellCurrencyAmount(value: Decimal) {
        if sellAmount == value  {
            return
        }
        fetchReceiveTimer?.cancel()
        receiveAmount = nil
        sellAmount = value

        if value > 0 {
            // Send a request when the user finishes entering amount
            fetchReceiveTimer = Just(())
                .delay(for: .seconds(0.8), scheduler: DispatchQueue.main)
                .sink(receiveValue: { [weak self] _ in
                    self?.fetchReceiveCurrencyAmount()
                })
        }
    }
    
    func setSellCurrency(_ currency: Currency) {
        if receiveCurrency == currency {
            receiveCurrency = sellCurrency
        }
        sellCurrency = currency
    }
    
    func setReceiveCurrency(_ currency: Currency) {
        if sellCurrency == currency {
            sellCurrency = receiveCurrency
        }
        receiveCurrency = currency
    }
    
    func refreshReceiveAmount() {
        if sellAmount > 0 {
            fetchReceiveCurrencyAmount()
        }
    }
    
    func resetUserData() {
        accountsManager.resetUserData()
    }
}

//MARK: -  Private
private extension ExchangeViewModel {
        
    func fetchReceiveCurrencyAmount() {
        receiveAmount = nil
        state = .fetching
        let lastSendSellAmount = sellAmount
        networkManager.sendExchangeCurrencyRequest(amount: sellAmount,
                                                   source: sellCurrency,
                                                   destination: receiveCurrency) { [weak self] result in
            guard let self else { return }
            if self.sellAmount != lastSendSellAmount {
                // skip this result as sell amount has been changed
                return
            }
                
            switch result {
            case .success(let response):
                if let value = Decimal(string: response.amount) {
                    guard self.receiveCurrency == Currency(rawValue: response.currency) else  {
                        self.state = .error
                        assertionFailure()
                        return
                    }
                    self.receiveAmount = value
                    self.state = .idle
                } else {
                    self.receiveAmount = nil
                    self.state = .error
                }
            case .failure(_):
                self.receiveAmount = nil
                self.state = .error
            }
        }
    }
}

