//
//  CurrencyConverterViewModel.swift
//  Currency Converter
//
//  Created by Abdurrahman on 15/09/2021.
//

import RxSwift
import RxCocoa

class CurrencyConverterViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    private var currenciesAfterConverting = [Currency]()
        
    var currenciesBehavior = BehaviorRelay<[Currency]>(value: [Currency(amount: "1000.00", currency: .eur),
                                                               Currency(amount: "0.00", currency: .usd),
                                                               Currency(amount: "0.00", currency: .jpy)])
    var amountBehavior = BehaviorRelay<String>(value: "")
    var commissionBehavior = BehaviorRelay<Double>(value: 0.0)
    var convertedFromAmountBehavior = BehaviorRelay<String>(value: "")
    var convertedToAmountBehavior = BehaviorRelay<String>(value: "")
    var fromCurrencyBehavior = BehaviorRelay<Currencies>(value: .eur)
    var toCurrencyBehavior = BehaviorRelay<Currencies>(value: .usd)
    var convertedFromCurrencyBehavior = BehaviorRelay<Currencies>(value: .eur)
    var convertedToCurrencyBehavior = BehaviorRelay<Currencies>(value: .usd)
    var loadingBehavior = BehaviorRelay<Bool>(value: false)
    var cannotSumbitBehavior = BehaviorRelay<Bool>(value: false)

    
    /// validating amount and currencies
    func isValid() -> Observable<Bool> {
        return Observable.combineLatest(amountBehavior, fromCurrencyBehavior, toCurrencyBehavior, convertedFromAmountBehavior).map { amount, fromCurrency, toCurrency, convertedAmount in
            return !amount.isEmpty && fromCurrency != toCurrency && !convertedAmount.isEmpty
        }.startWith(false)
    }
    
    func convert() {
        convert(fromAmount: amountBehavior.value,
                fromCurrency: fromCurrencyBehavior.value,
                toCurrency: toCurrencyBehavior.value)
    }
    
    /// convert
    func convert(fromAmount: String, fromCurrency: Currencies, toCurrency: Currencies) {
        loadingBehavior.accept(true)
        /// API request
        let request = ApiManager.convertCurrency(fromAmount: fromAmount, fromCurrency: fromCurrency.rawValue, toCurrency: toCurrency.rawValue)
        ApiProvider.rx.request(request)
            .mapString(atKeyPath: "amount")
            .subscribe { (value) in
                self.loadingBehavior.accept(false)
                self.convertedFromAmountBehavior.accept(fromAmount)
                self.convertedToAmountBehavior.accept(value)
                self.convertedFromCurrencyBehavior.accept(fromCurrency)
                self.convertedToCurrencyBehavior.accept(toCurrency)
                self.calculateCommission()
                self.calculateBalance()
            } onError: { (error) in
                self.loadingBehavior.accept(false)
                print(error)
            }.disposed(by: disposeBag)
    }
    
    /// calculate the commission
    func calculateCommission() {
        Constants.freeConvetableTimes -= 1
        if Constants.freeConvetableTimes < 1 {
            let commission = Constants.commission * Double(convertedFromAmountBehavior.value)!
            commissionBehavior.accept(commission)
        }
    }
    
    /// calculate the balance
    func calculateBalance() {
        var currencies = currenciesBehavior.value
        /// editedCurrencies is used to stop the for loop once from and to currencies and edited
        var editedCurrencies = 0
        for i in 0..<currencies.count {
            if editedCurrencies > 1 {
                break
            }
            if currenciesBehavior.value[i].currency.rawValue == convertedFromCurrencyBehavior.value.rawValue {
                let amount = Double(currencies[i].amount)! - Double(convertedFromAmountBehavior.value)! - commissionBehavior.value
                if amount < 0 {
                    cannotSumbitBehavior.accept(true)
                    return
                }
                currencies[i] = Currency(amount: amount.rounded(to: 2), currency: currencies[i].currency)
                editedCurrencies += 1
            }
            if currenciesBehavior.value[i].currency.rawValue == convertedToCurrencyBehavior.value.rawValue {
                let amount = Double(currencies[i].amount)! + Double(convertedToAmountBehavior.value)!
                currencies[i] = Currency(amount: amount.rounded(to: 2), currency: currencies[i].currency)
                editedCurrencies += 1
            }
        }
        currenciesAfterConverting = currencies
    }
    
    /// update the balance to the collection view
    func updateBalance() {
        currenciesBehavior.accept(currenciesAfterConverting)
    }
    
    /// set from currency when selecting from the drop down
    func setFromCurrency(currencyText: String) {
        fromCurrencyBehavior.accept(getCurrency(currencyText: currencyText))
        if !amountBehavior.value.isEmpty {
            convert()
        }
    }
    
    /// set to currency when selecting from the drop down
    func setToCurrency(currencyText: String) {
        toCurrencyBehavior.accept(getCurrency(currencyText: currencyText))
        if !amountBehavior.value.isEmpty {
            convert()
        }
    }
    
    /// get the selected "Currency" object by the selected currency string
    func getCurrency(currencyText: String) -> Currencies {
        var currency: Currencies?
        switch currencyText {
        case Currencies.eur.rawValue:
            currency = .eur
        case Currencies.usd.rawValue:
            currency = .usd
        case Currencies.jpy.rawValue:
            currency = .jpy
        default:
            return .eur
        }
        return currency!
    }
}
