//
//  ExchangeViewModelProtocol.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import Foundation

protocol ExchangeViewModelProtocol {
    var accountsPublisher: Published<[Account]>.Publisher { get }
    
    var state: ExchangeViewModel.State { get }
    var statePublisher: Published<ExchangeViewModel.State>.Publisher { get }
    
    var sellCurrencyPublisher: Published<Currency>.Publisher { get }
    var receiveAmountPublisher: Published<Decimal?>.Publisher { get }
    var receiveCurrencyPublisher: Published<Currency>.Publisher { get }
    
    var availableCurrencies: [Currency] { get }
    
    func setSellCurrency(_ currency: Currency)
    func setReceiveCurrency(_ currency: Currency)
    func setSellCurrencyAmount(value: Decimal)
    
    func refreshReceiveAmount()
    func makeExchange() -> Result<ExchangeCurrencyReceipt, ExchangeCurrencyError>

    // reset
    func resetUserData()
}
