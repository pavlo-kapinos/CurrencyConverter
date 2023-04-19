//
//  AccountsManager.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import Foundation

enum AccountUpdateError: Error {
    case notEnoughMoney(String), noAccount, exceedLimit, nothingToExchange
}

extension AccountUpdateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notEnoughMoney(let amount): return NSLocalizedString("Not Enough Money.\nSum + Commission Fee = \(amount)", comment: "")
        case .noAccount: return NSLocalizedString("Account Does Not exist", comment: "")
        case .exceedLimit: return NSLocalizedString("Exceeded Limit", comment: "")
        case .nothingToExchange: return NSLocalizedString("Nothing To Exchange", comment: "")
        }
    }
}

class AccountsManager: AccountsManagerProtocol {
    var accountsPublisher: Published<[Account]>.Publisher { $accounts }
    
    private enum DefaultsKeys {
        static let userAccounts = "AccountsManagerUserAccounts"
        static let exchangeTransactionCounter = "AccountsManagerExchangeTransactionCounter"
    }
    
    @Published private(set) var accounts: [Account] = []
    private var exchangeTransactionCounter: UInt = 0
    private var userDefaults: UserDefaults { return UserDefaults.standard }
    
    init(loadData: Bool = false) {
        if loadData {
            loadUserData()
        }
        createNewAccountsIfNeeded()
    }
    
    init(balance: [Currency: Decimal]) {
        accounts = Currency.allCases.map {
            Account(id: UUID().uuidString, currency: $0, amount: balance[$0] ?? 0)
        }
        saveUserData()
    }
    
    func perform(operation: FinanceOperation) throws -> FinanceReceipt {
        switch operation {
        case let exchangeOperation as ExchangeCurrencyOperation:
            let receipt = try perform(exchange: exchangeOperation)
            exchangeTransactionCounter += 1
            saveUserData()
            return receipt
        default:
            return EmptyReceipt()
        }
    }
    
    func resetUserData() {
        let balance: [Currency: Decimal] = [.EUR: 10000, .USD: 500]
        accounts = Currency.allCases.map {
            Account(id: UUID().uuidString, currency: $0, amount: balance[$0] ?? 0)
        }
        exchangeTransactionCounter = 0
        saveUserData()
    }
    
    func getAmountForCurrency(_ currency: Currency) -> Decimal {
        let amount = accounts.first{ $0.currency == currency }?.amount
        precondition(amount != nil)
        return amount ?? 0.0
    }
}

private extension AccountsManager {
    func createNewAccountsIfNeeded() {
        Currency.allCases.forEach { currency in
            if !accounts.contains(where: { $0.currency == currency }) {
                let createNewAccount = Account(id: UUID().uuidString, currency: currency, amount: 0)
                accounts.append(createNewAccount)
                saveUserData()
            }
        }
    }

    func loadUserData() {
        if let jsonData = UserDefaults.standard.data(forKey: DefaultsKeys.userAccounts),
           let accounts = try? JSONDecoder().decode([Account].self, from: jsonData) {
            self.accounts = accounts
        }
        exchangeTransactionCounter = userDefaults.object(forKey: DefaultsKeys.exchangeTransactionCounter) as? UInt ?? 0
    }
    
    func saveUserData() {
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(accounts) {
            userDefaults.set(jsonData, forKey: DefaultsKeys.userAccounts)
        }
        userDefaults.set(exchangeTransactionCounter, forKey: DefaultsKeys.exchangeTransactionCounter)
    }
}

//MARK: - Exchange Currency Operation

enum CommissionConstants {
    static let amountFirstFreeOfChargeTransaction: UInt = 5
    static let chargePercentOnTransaction: Decimal = 0.7
}

enum ExchangeCurrencyError: Error {
    case theSameCurrency, noReceiveAmount, withdrawal(AccountUpdateError), deposit(AccountUpdateError), withdrawalReturn(AccountUpdateError), `internal`
}

extension ExchangeCurrencyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .theSameCurrency: return NSLocalizedString("Nothing to exchange. The same currency.", comment: "")
        case .noReceiveAmount: return NSLocalizedString("Receive Amount is empty", comment: "")
        case .withdrawal(let error): return NSLocalizedString("Withdrawal Error.\n\(error.localizedDescription)", comment: "")
        case .deposit(let error): return NSLocalizedString("Deposit Error.\n\(error.localizedDescription)", comment: "")
        case .withdrawalReturn(let error): return NSLocalizedString("Withdrawal Return Error.\n\(error.localizedDescription)", comment: "")
        case .internal: return NSLocalizedString("Internal Error.", comment: "")
        }
    }
}

private extension AccountsManager {
    func getCommissionFee(for operation: ExchangeCurrencyOperation) -> Decimal {
        // The first N currency conversions are free
        if exchangeTransactionCounter < CommissionConstants.amountFirstFreeOfChargeTransaction {
            return 0
        }
        // Commission on transaction
        return operation.sourceAmount * CommissionConstants.chargePercentOnTransaction / 100
    }
    
    func perform(exchange operation: ExchangeCurrencyOperation) throws -> ExchangeCurrencyReceipt {
        if operation.sourceCurrency == operation.destinationCurrency {
            throw ExchangeCurrencyError.theSameCurrency
        }
        
        let fee = getCommissionFee(for: operation)
        // withdraw from the account
        do {
            try withdraw(operation.sourceCurrency, with: operation.sourceAmount + fee)
        }
        catch let error as AccountUpdateError {
            throw ExchangeCurrencyError.withdrawal(error)
        }
        // deposit to another account
        do {
            try deposit(operation.destinationCurrency, with: operation.destinationAmount)
        }
        catch let error as AccountUpdateError {
            // Can't deposit, will try to return money...
            do {
                try deposit(operation.sourceCurrency, with: operation.sourceAmount + fee)
            }
            catch let error as AccountUpdateError {
                throw ExchangeCurrencyError.withdrawalReturn(error)
            }
            throw ExchangeCurrencyError.deposit(error)
        }
        return ExchangeCurrencyReceipt(operation: operation, commissionFee: fee, transactionNumber: exchangeTransactionCounter)
    }
    
    func deposit(_ currency: Currency, with amount: Decimal) throws {
        if amount <= 0 {
            throw AccountUpdateError.nothingToExchange
        }
        guard let index = accounts.firstIndex(where: { $0.currency == currency }) else {
            throw AccountUpdateError.noAccount
        }
        var account = accounts[index]
        account.amount += amount
        accounts[index] = account
    }
    
    func withdraw(_ currency: Currency, with amount: Decimal) throws {
        if amount <= 0 {
            throw AccountUpdateError.nothingToExchange
        }
        guard let index = accounts.firstIndex(where: { $0.currency == currency }) else {
            throw AccountUpdateError.noAccount
        }
        
        var account = accounts[index]
        account.amount -= amount
        if account.amount < 0.0 {
            throw AccountUpdateError.notEnoughMoney("\(amount.currencyString) \(currency.code)")
        }
        accounts[index] = account
    }
    
}
