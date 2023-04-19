//
//  ExchangeViewController.swift
//  CurrencyConverter
//
//  Created by Pavlo Kapinos on 01.04.2023.
//

import UIKit
import Combine

class ExchangeViewController: UIViewController {
    
    enum Constants {
        static let maxSellNumberLength = 15
    }
    
    @IBOutlet private(set) weak var accountsCollectionView: StripeCollectionView!
    
    @IBOutlet private(set) weak var sellAmountTextField: UITextField!
    @IBOutlet private(set) weak var sellCurrencyButton: UIButton!
    
    @IBOutlet private(set) weak var receiveAmountTextField: UITextField!
    @IBOutlet private(set) weak var receiveCurrencyButton: UIButton!
    
    @IBOutlet private(set) weak var submitButton: UIButton!
    
    private var subscriptions = [AnyCancellable]()
    var alertStyle: UIAlertController.Style { return UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet }
    
    let vm: ExchangeViewModelProtocol
    
    //MARK: - Lifecycle
    init(vm: ExchangeViewModelProtocol) {
        self.vm = vm
        super.init(nibName: "ExchangeViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Currency Converter"
        applyAppearance()
        addResetUserButtonOnNavigationBar()

        sellAmountTextField.text = nil
        receiveAmountTextField.text = nil

        sellAmountTextField.delegate = self
        sellAmountTextField.addTarget(self, action: #selector(sellTextFieldDidChanged), for: .editingChanged)

        binding()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // it hides keyboard by click on outside textview
        view.endEditing(true)
        // attempt to refresh on error state
        if vm.state == .error {
            vm.refreshReceiveAmount()
        }
        super.touchesBegan(touches, with: event)
    }
    
    //MARK: - Actions
    
    @IBAction func scrollToLeftButton(_ sender: Any) {
        accountsCollectionView.scrollToLeft()
    }
    
    @IBAction func scrollToRightButton(_ sender: Any) {
        accountsCollectionView.scrollToRight()
    }
    
    @IBAction func onSubmitButtonTap(_ sender: Any) {
        let result = vm.makeExchange()
        switch result {
        case .success(let receipt):
            showReceipt(receipt)
        case .failure(let error):
            if case .noReceiveAmount = error {
                // do nothing, wait for result
            } else {
                showError(error)
            }
        }
    }
    
    @objc func sellTextFieldDidChanged() {
        guard let sellText = sellAmountTextField.text else { return }
        let formattedText = sellText.currencyInputFormatting()
        sellAmountTextField.text = formattedText
        vm.setSellCurrencyAmount(value: formattedText.toCurrencyDecimal() ?? 0)
    }
    
    //MARK: - Private
    private func binding() {
        vm.accountsPublisher.sink { [weak self] accounts in
            self?.accountsCollectionView.items = accounts.map { "\($0.amount.currencyString) \($0.currency)" }
        }.store(in: &subscriptions)
        
        vm.statePublisher.sink { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .fetching:
                    self?.receiveAmountTextField.text = "Fetching..."
                    self?.receiveAmountTextField.textColor = .label
                case .error:
                    self?.receiveAmountTextField.text = "No server data!"
                    self?.receiveAmountTextField.textColor = .systemRed
                default:
                    self?.receiveAmountTextField.textColor = .systemGreen
                }
            }
        }.store(in: &subscriptions)
        
        vm.receiveAmountPublisher.sink { [weak self] value in
            DispatchQueue.main.async {
                if let value {
                    self?.receiveAmountTextField.text = "+ \(value.currencyString)"
                } else {
                    self?.receiveAmountTextField.text = ""
                }
            }
        }.store(in: &subscriptions)
        
        Publishers.CombineLatest(vm.sellCurrencyPublisher, vm.receiveCurrencyPublisher).sink { [weak self] sellCurrency, receiveCurrency in
            DispatchQueue.main.async {
                self?.updateCurrencyPopUpButtons(sellCurrency: sellCurrency, receiveCurrency: receiveCurrency)
                self?.vm.refreshReceiveAmount()
            }
        }
        .store(in: &subscriptions)
    }
    
    func updateCurrencyPopUpButtons(sellCurrency: Currency, receiveCurrency: Currency) {
        // Sell Currency PopUP
        let sellCurrencies = vm.availableCurrencies.filter { $0 != sellCurrency }
        let sellActionHandler: ((UIAction) -> Void) = { [weak self] action in
            guard let actionCurrency = Currency(rawValue: action.title) else { return }
            self?.vm.setSellCurrency(actionCurrency)
        }
        let sellActions = sellCurrencies.map { UIAction(title: $0.code, handler: sellActionHandler) }
        sellCurrencyButton.menu = UIMenu(children: sellActions)
        sellCurrencyButton.setTitle(sellCurrency.code, for: .normal)
        
        // Receive Currency PopUP
        let receiveCurrencies = vm.availableCurrencies.filter { $0 != sellCurrency && $0 != receiveCurrency }
        let receiveActionHandler: ((UIAction) -> Void) = { [weak self] action in
            guard let actionCurrency = Currency(rawValue: action.title) else { return }
            self?.vm.setReceiveCurrency(actionCurrency)
        }
        let receiveActions = receiveCurrencies.map { UIAction(title: $0.code, handler: receiveActionHandler) }
        receiveCurrencyButton.menu = UIMenu(children: receiveActions)
        receiveCurrencyButton.setTitle(receiveCurrency.code, for: .normal)
    }
    
    func showReceipt(_ receipt: ExchangeCurrencyReceipt) {
        guard let operation = receipt.operation as? ExchangeCurrencyOperation else {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        
        let message =
        """
        Currency Exchanged
        ------------------------------
        from: \(operation.sourceAmount.currencyString) \(operation.sourceCurrency.code)
        to: \(operation.destinationAmount.currencyString) \(operation.destinationCurrency.code)
        Commission Fee: \(receipt.commissionFee.currencyString) \(operation.sourceCurrency.code)
        ------------------------------
        Transaction number: \(receipt.transactionNumber + 1)
        \(dateFormatter.string(from:receipt.date))
        """

        let alert = UIAlertController(title: message, message: nil, preferredStyle: alertStyle)
        let cancelAction = UIAlertAction(title: "OK", style: .default) { [weak self] action in
            self?.sellAmountTextField.text = nil
            self?.vm.setSellCurrencyAmount(value: 0)
        }
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: alertStyle)
        let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

//MARK: - Navigation Bar Appearance
private extension ExchangeViewController {
    func applyAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        navigationController?.navigationBar.barStyle = .black
        
        submitButton.layer.cornerRadius = submitButton.frame.height / 2.0 - 1
    }
    
    func addResetUserButtonOnNavigationBar() {
        let button = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.arrow.triangle.2.circlepath"), style: .plain, target: self, action: #selector(resetUserDataButtonAction))
        button.tintColor = .white
        navigationItem.leftBarButtonItem = button
    }
    
    @objc func resetUserDataButtonAction() {
        vm.resetUserData()
    }
}

extension ExchangeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == sellAmountTextField {
            // check on 'max length'
            guard let currentText = textField.text,
                  let stringRange = Range(range, in: currentText) else {
                return false
            }
            let newString = currentText.replacingCharacters(in: stringRange, with: string)
            guard newString.count <= Constants.maxSellNumberLength else {
                return false
            }
            // check on correct symbols
            let allowedCharacterSet = CharacterSet(charactersIn: "1234567890.")
            return allowedCharacterSet.isSuperset(of: CharacterSet(charactersIn: string))
        } else {
            return true
        }
    }
}
