//
//  String+CurrencyFormatting.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 02.04.2023.
//

import Foundation

extension Decimal {
    var currencyString: String {
        return self.description.toCurrencyString()
    }
}

extension String {
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = ""
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    func toCurrencyDecimal() -> Decimal? {
        if let number = currencyFormatter.number(from: self) {
            return number.decimalValue
        }
        return nil
    }
    
    func toCurrencyString() -> String {
        if let number = currencyFormatter.number(from: self) {
            return currencyFormatter.string(from: number) ?? self
        }
        return self
    }
    
    func currencyInputFormatting() -> String {
        guard let regex = try? NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive) else { return self }
        let amountWithPrefix = regex.stringByReplacingMatches(in: self,
                                                              options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                              range: NSMakeRange(0, self.count),
                                                              withTemplate: "")
        let double = (amountWithPrefix as NSString).doubleValue
        let number = NSNumber(value: (double / 100))
    
        guard number != 0 else {
            return ""
        }
        return currencyFormatter.string(from: number) ?? ""
    }
    
}
