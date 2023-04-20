//
//  StripeCollectionView.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import UIKit

class StripeCollectionView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    private let cellReuseIdentifier = "StripeCellIdentifier"
    
    var items: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        register(StripeCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        dataSource = self
        delegate = self
    }
    
    func scrollToLeft() {
        if items.isEmpty { return }
        scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: true)
    }
    
    func scrollToRight() {
        scrollToItem(at: IndexPath(item: items.count - 1, section: 0), at: .right, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = items[indexPath.item]
        return StripeCollectionViewCell.makeLabel(with: item).frame.insetBy(dx: -10, dy: 0).size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) 
        guard let accountCell = cell as? StripeCollectionViewCell else { return cell }
        let account = items[indexPath.item]
        accountCell.updateLabel(with: account)
        return accountCell
    }
}
