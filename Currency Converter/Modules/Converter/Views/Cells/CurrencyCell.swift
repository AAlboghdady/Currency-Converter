//
//  CurrencyCell.swift
//  Currency Converter
//
//  Created by Abdurrahman on 15/09/2021.
//

import UIKit

class CurrencyCell: UICollectionViewCell {

    @IBOutlet weak var balanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(currency: Currency) {
        balanceLabel.text = currency.amount + " " + currency.currency.rawValue
    }
}
