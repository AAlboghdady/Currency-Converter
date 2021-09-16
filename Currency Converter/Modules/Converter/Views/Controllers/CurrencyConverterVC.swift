//
//  CurrencyConverterVC.swift
//  Currency Converter
//
//  Created by Abdurrahman on 15/09/2021.
//

import UIKit
import RxSwift
import iOSDropDown

class CurrencyConverterVC: UIViewController {
    
    @IBOutlet weak var currenciesCollectionView: UICollectionView!
    @IBOutlet weak var sellTextField: UITextField!
    @IBOutlet weak var receiveTextField: UITextField!
    @IBOutlet weak var sellCurrencyDropDown: DropDown!
    @IBOutlet weak var receiveCurrencyDropDown: DropDown!
    @IBOutlet weak var submitButton: UIButton!
    
    /// loading indicator view
    var activityIndicator: UIActivityIndicatorView?
    /// gradients
    var navigationGradient: CAGradientLayer?
    let navigationGradientView: UIView = {
        let view = UIView()
        return view
    }()
    var submitButtonGradient: CAGradientLayer?
    /// view model and dispose bag
    let viewModel = CurrencyConverterViewModel()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        setupSubmitButton()
        setupCarFromCurrencyDrobDown()
        setupCarToCurrencyDrobDown()
        bindViews()
        setupCollectionView()
        subscribeToCurrencies()
        subscribeToConvertedAmount()
        setupLoading()
        subscribeToLoading()
        subscribeToCanSumbit()
        subscribeToSubmitButton()
    }
    
    func setupSubmitButtonGradient() {
        submitButtonGradient = CAGradientLayer()
        submitButtonGradient!.colors = [Constants.leftColor, Constants.rightColor]
        submitButtonGradient!.locations = [0.0 , 1.0]
        submitButtonGradient!.startPoint = CGPoint(x: 0.0,y: 1.0)
        submitButtonGradient!.endPoint = CGPoint(x: 1.0,y: 1.0)
        submitButtonGradient!.frame = submitButton.bounds
        submitButtonGradient!.cornerRadius = submitButton.frame.size.height / 2
        submitButton.layer.insertSublayer(submitButtonGradient!, at: 0)
    }
    
    func setupSubmitButton() {
        setupSubmitButtonGradient()
        /// making the button rounded in corner
        submitButton.layer.cornerRadius = submitButton.frame.size.height / 2
    }
    
    /// registering the cell nib
    func setupCollectionView() {
        currenciesCollectionView.register(UINib(nibName: StoryBoardCells.currency.rawValue, bundle: nil), forCellWithReuseIdentifier: StoryBoardCells.currency.rawValue)
    }
    
    /// setup from currency drop down
    func setupCarFromCurrencyDrobDown() {
        sellCurrencyDropDown.optionArray.append(contentsOf: viewModel.currenciesBehavior.value.map{$0.currency.rawValue})
        /// didSelect a currency
        sellCurrencyDropDown.didSelect{(selectedText, index, id) in
            self.sellTextField.text = ""
            self.viewModel.setFromCurrency(currencyText: selectedText)
        }
    }
    
    /// setup to currency drop down
    func setupCarToCurrencyDrobDown() {
        receiveCurrencyDropDown.optionArray.append(contentsOf: viewModel.currenciesBehavior.value.map{$0.currency.rawValue})
        /// didSelect a currency
        receiveCurrencyDropDown.didSelect{(selectedText, index, id) in
            self.viewModel.setToCurrency(currencyText: selectedText)
        }
    }
    
    func bindViews() {
        /// binding amount to amountBehavior in viewModel
        sellTextField.rx.controlEvent([.editingChanged])
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .asObservable().subscribe({ [unowned self] _ in
                self.viewModel.amountBehavior.accept(self.sellTextField.text!)
                if self.viewModel.fromCurrencyBehavior.value.rawValue == self.viewModel.toCurrencyBehavior.value.rawValue { return }
                self.viewModel.convert()
            }).disposed(by: disposeBag)
        /// validating amount and currencies to enable submitButton
        viewModel.isValid().bind(to: submitButton.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isValid().map { $0 ? 1 : 0.3 }.bind(to: submitButton.rx.alpha).disposed(by: disposeBag)
    }
    
    /// subscribe to currencies changes
    func subscribeToCurrencies() {
        viewModel.currenciesBehavior.asObservable()
            .bind(to: currenciesCollectionView
                    .rx
                    .items(cellIdentifier: StoryBoardCells.currency.rawValue,
                           cellType: CurrencyCell.self)) { _, currency, cell in
                cell.configure(currency: currency)
            }
            .disposed(by: disposeBag)
    }
    
    /// subscribe to loading
    func subscribeToLoading() {
        viewModel.loadingBehavior.subscribe { (isLoading) in
            self.showLoading(isLoading)
        }.disposed(by: disposeBag)
    }
    
    /// subscribe to can submit the conversion
    func subscribeToCanSumbit() {
        viewModel.cannotSumbitBehavior.subscribe { (cannotSumbit) in
            self.showCannotSubmitAlert(cannotSumbit)
        }.disposed(by: disposeBag)
    }
    
    /// displaying an error alert
    func showCannotSubmitAlert(_ cannotSumbit: Bool) {
        /// validate if the cannot sumbit the conversion
        if !cannotSumbit { return }
        let title = "Can't sumbit"
        var message = "Your balance is not enough"
        if viewModel.commissionBehavior.value > 0 {
            message += " with the commission"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
        alert.addAction(doneAction)
        present(alert, animated: true, completion: nil)
    }
    
    /// setup loading indicator view
    func setupLoading() {
        activityIndicator = UIActivityIndicatorView()
        activityIndicator!.center = view.center
        activityIndicator!.hidesWhenStopped = true
        if #available(iOS 13.0, *) {
            activityIndicator!.style = .large
        } else {
            activityIndicator!.style = .gray
        }
        view.addSubview(activityIndicator!)
    }
    
    /// show loading indicator view
    func showLoading(_ loading: Bool) {
        if loading && !activityIndicator!.isAnimating {
            activityIndicator!.startAnimating()
        } else {
            activityIndicator!.stopAnimating()
        }
    }
    
    /// subscribe to the converted amount
    func subscribeToConvertedAmount() {
        viewModel.convertedToAmountBehavior.asObservable()
            .subscribe(onNext: { (amount) in
                self.receiveTextField.text = amount.isEmpty ? "" : "+ " + amount
        }).disposed(by: disposeBag)
    }
    
    /// subscribe to the submit button tap
    func subscribeToSubmitButton() {
        submitButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe { [unowned self] _ in
                if self.viewModel.cannotSumbitBehavior.value { return }
                self.submit()
                self.viewModel.updateBalance()
            }.disposed(by: disposeBag)
    }
    
    /// displaying the submit alert
    func submit() {
        let title = "Currency converted"
        var message = "You have converted \(Double(viewModel.convertedFromAmountBehavior.value)!.rounded(to: 2)) \(viewModel.convertedFromCurrencyBehavior.value.rawValue) to \(Double(viewModel.convertedToAmountBehavior.value)!.rounded(to: 2)) \(viewModel.convertedToCurrencyBehavior.value.rawValue)."
        if viewModel.commissionBehavior.value > 0 {
            /// adding the commission
            message += " Commission Fee - \(viewModel.commissionBehavior.value.rounded(to: 2)) \(viewModel.convertedFromCurrencyBehavior.value.rawValue)."
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
            /// reseting sellTextField and receiveTextField
            self.sellTextField.text = ""
            self.receiveTextField.text = ""
        }
        alert.addAction(doneAction)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - setup navigation controller
extension CurrencyConverterVC {
    /// setup navigation controller
    func setupNavigationController() {
        navigationItem.title = "Currency converter"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        clearNavBar()
        setupNavigationGradient()
    }
    
    /// clear navigation bar background
    func clearNavBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.isTranslucent = true
    }
    
    /// setup navigation bar gradient
    func setupNavigationGradient() {
        let height = Int(navigationController?.navigationBar.frame.height ?? 0) + Int(UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)
        navigationGradient = CAGradientLayer()
        navigationGradient!.colors = [Constants.leftColor, Constants.rightColor]
        navigationGradient!.locations = [0.0 , 1.0]
        navigationGradient!.startPoint = CGPoint(x: 0.0, y: 1.0)
        navigationGradient!.endPoint = CGPoint(x: 1.0, y: 1.0)
        navigationGradient!.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: CGFloat(height))
        view.addSubview(navigationGradientView)
        NSLayoutConstraint.activate([
            navigationGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationGradientView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
        navigationGradientView.layer.insertSublayer(navigationGradient!, at: 0)
    }
}
