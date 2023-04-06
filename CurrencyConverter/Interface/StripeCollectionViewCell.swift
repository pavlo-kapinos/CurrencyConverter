//
//  StripeCollectionViewCell.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import UIKit

class StripeCollectionViewCell: UICollectionViewCell {
 
    static func makeLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.sizeToFit()
        return label
    }
    
    private var label = UILabel()
    
    func updateLabel(with text: String) {
        label.removeFromSuperview()
        label = Self.makeLabel(with: text)
        addSubview(label)
    }
}
