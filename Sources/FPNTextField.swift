//
//  FlagPhoneNumberTextField.swift
//  FlagPhoneNumber
//
//  Created by Aurélien Grifasi on 06/08/2017.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import UIKit

open class FPNTextField: UITextField {

	/// The size of the flag button
	@objc open var flagButtonSize: CGSize = CGSize(width: 32, height: 32) {
		didSet {
			layoutIfNeeded()
		}
	}

	private var flagWidthConstraint: NSLayoutConstraint?
	private var flagHeightConstraint: NSLayoutConstraint?

	private var phoneCodeTextField: UITextField = UITextField()

	private lazy var phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
	private var nbPhoneNumber: NBPhoneNumber?
	private var formatter: NBAsYouTypeFormatter?

	open var flagButton: UIButton = ButtonWithImage()
    
    public let phoneCodeLabel = UILabel()
    public let letfImageView = UIImageView()

	open override var font: UIFont? {
		didSet {
			phoneCodeTextField.font = font
		}
	}

	open override var textColor: UIColor? {
		didSet {
			phoneCodeTextField.textColor = textColor
		}
	}

	/// Present in the placeholder an example of a phone number according to the selected country code.
	/// If false, you can set your own placeholder. Set to true by default.
	@objc open var hasPhoneNumberExample: Bool = true {
		didSet {
			if hasPhoneNumberExample == false {
				placeholder = nil
			}
			updatePlaceholder()
		}
	}

	open var countryRepository = FPNCountryRepository()

	open var selectedCountry: FPNCountry? {
		didSet {
			updateUI()
		}
	}

	/// Input Accessory View for the texfield
	@objc open var textFieldInputAccessoryView: UIView?

	open lazy var pickerView: FPNCountryPicker = FPNCountryPicker()

	@objc public enum FPNDisplayMode: Int {
		case picker
		case list
	}

	@objc open var displayMode: FPNDisplayMode = .picker

	init() {
		super.init(frame: .zero)

		setup()
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)

		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		setup()
	}

	private func setup() {
		leftViewMode = .always

		setupFlagButton()
		setupPhoneCodeTextField()
		setupLeftView()

		keyboardType = .numberPad
		autocorrectionType = .no
		addTarget(self, action: #selector(didEditText), for: .editingChanged)
		addTarget(self, action: #selector(displayNumberKeyBoard), for: .touchDown)

		if let regionCode = Locale.current.regionCode, let countryCode = FPNCountryCode(rawValue: regionCode) {
			setFlag(countryCode: countryCode)
		} else {
			setFlag(countryCode: FPNCountryCode.FR)
		}
	}

	private func setupFlagButton() {
		flagButton.accessibilityLabel = "flagButton"
		flagButton.addTarget(self, action: #selector(displayCountries), for: .touchUpInside)
		flagButton.translatesAutoresizingMaskIntoConstraints = false
        
        phoneCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        letfImageView.translatesAutoresizingMaskIntoConstraints = false
        letfImageView.contentMode = .scaleAspectFit
        letfImageView.image = UIImage(named: "Arrow", in: Bundle.flagIcons, compatibleWith: nil)
	}

	private func setupPhoneCodeTextField() {
		phoneCodeTextField.font = font
		phoneCodeTextField.isUserInteractionEnabled = false
		phoneCodeTextField.translatesAutoresizingMaskIntoConstraints = false
	}

	private func setupLeftView() {
		leftView = UIView()
		leftViewMode = .always
		phoneCodeTextField.semanticContentAttribute = .forceLeftToRight
        
        leftView?.addSubview(phoneCodeLabel)
        leftView?.addSubview(letfImageView)
		leftView?.addSubview(flagButton)
		leftView?.addSubview(phoneCodeTextField)
        
        phoneCodeLabel.leftAnchor.constraint(equalTo: leftView!.leftAnchor, constant:  0).isActive = true
        phoneCodeLabel.heightAnchor.constraint(equalTo: leftView!.heightAnchor, constant:  0).isActive = true
        letfImageView.leftAnchor.constraint(equalTo: phoneCodeLabel.rightAnchor, constant: 10).isActive = true
        letfImageView.widthAnchor.constraint(equalToConstant: 12).isActive = true
        letfImageView.heightAnchor.constraint(equalToConstant: 12).isActive = true
        letfImageView.centerYAnchor.constraint(equalTo: leftView!.centerYAnchor, constant: 0).isActive = true
        
        flagButton.leftAnchor.constraint(equalTo: phoneCodeLabel.leftAnchor, constant: 0).isActive = true
        flagButton.heightAnchor.constraint(equalTo: leftView!.heightAnchor, constant: 0).isActive = true
        flagButton.rightAnchor.constraint(equalTo: letfImageView.rightAnchor, constant: 0).isActive = true
        
        phoneCodeTextField.leftAnchor.constraint(equalTo: flagButton.rightAnchor, constant: 16).isActive = true
        phoneCodeTextField.rightAnchor.constraint(equalTo: leftView!.rightAnchor, constant: 0).isActive = true
        
        phoneCodeTextField.topAnchor.constraint(equalTo: leftView!.topAnchor, constant: 0).isActive = true
        phoneCodeTextField.bottomAnchor.constraint(equalTo: leftView!.bottomAnchor, constant: 0).isActive = true
	}

	open override func updateConstraints() {
		super.updateConstraints()

		//flagWidthConstraint?.constant = flagButtonSize.width
		//flagHeightConstraint?.constant = flagButtonSize.height
	}

//	open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
//		let size = leftViewSize
//		let width: CGFloat = min(bounds.size.width, size.width)
//		let height: CGFloat = min(bounds.size.height, size.height)
//		let newRect: CGRect = CGRect(x: bounds.minX, y: bounds.minY, width: width, height: height)
//
//		return newRect
//	}

	@objc private func displayNumberKeyBoard() {
		switch displayMode {
		case .picker:
			tintColor = .gray
			inputView = nil
			inputAccessoryView = textFieldInputAccessoryView
			reloadInputViews()
		default:
			break
		}
	}

	@objc private func displayCountries() {
		switch displayMode {
		case .picker:
			pickerView.setup(repository: countryRepository)

			tintColor = .clear
			inputView = pickerView
			inputAccessoryView = getToolBar(with: getCountryListBarButtonItems())
			reloadInputViews()
			becomeFirstResponder()

			pickerView.didSelect = { [weak self] country in
				self?.fpnDidSelect(country: country)
			}

			if let selectedCountry = selectedCountry {
				pickerView.setCountry(selectedCountry.code)
			} else if let regionCode = Locale.current.regionCode, let countryCode = FPNCountryCode(rawValue: regionCode) {
				pickerView.setCountry(countryCode)
			} else if let firstCountry = countryRepository.countries.first {
				pickerView.setCountry(firstCountry.code)
			}
		case .list:
			(delegate as? FPNTextFieldDelegate)?.fpnDisplayCountryList()
		}
	}

	@objc private func dismissCountries() {
		resignFirstResponder()
		inputView = nil
		inputAccessoryView = nil
		reloadInputViews()
	}

	private func fpnDidSelect(country: FPNCountry) {
		(delegate as? FPNTextFieldDelegate)?.fpnDidSelectCountry(name: country.name, dialCode: country.phoneCode, code: country.code.rawValue)
		selectedCountry = country
	}

	// - Public

	/// Get the current formatted phone number
	open func getFormattedPhoneNumber(format: FPNFormat) -> String? {
		return try? phoneUtil.format(nbPhoneNumber, numberFormat: convert(format: format))
	}

	/// For Objective-C, Get the current formatted phone number
	@objc open func getFormattedPhoneNumber(format: Int) -> String? {
		if let formatCase = FPNFormat(rawValue: format) {
			return try? phoneUtil.format(nbPhoneNumber, numberFormat: convert(format: formatCase))
		}
		return nil
	}

	/// Get the current raw phone number
	@objc open func getRawPhoneNumber() -> String? {
		let phoneNumber = getFormattedPhoneNumber(format: .E164)
		var nationalNumber: NSString?

		phoneUtil.extractCountryCode(phoneNumber, nationalNumber: &nationalNumber)

		return nationalNumber as String?
	}

	/// Set directly the phone number. e.g "+33612345678"
	@objc open func set(phoneNumber: String) {
		let cleanedPhoneNumber: String = clean(string: phoneNumber)

		if let validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber) {
			if validPhoneNumber.italianLeadingZero {
				text = "0\(validPhoneNumber.nationalNumber.stringValue)"
			} else {
				text = validPhoneNumber.nationalNumber.stringValue
			}
			setFlag(countryCode: FPNCountryCode(rawValue: phoneUtil.getRegionCode(for: validPhoneNumber))!)
		}
	}

	/// Set the country image according to country code. Example "FR"
	open func setFlag(countryCode: FPNCountryCode) {
		let countries = countryRepository.countries

		for country in countries {
			if country.code == countryCode {
				return fpnDidSelect(country: country)
			}
		}
	}

	/// Set the country image according to country code. Example "FR"
	@objc open func setFlag(key: FPNOBJCCountryKey) {
		if let code = FPNOBJCCountryCode[key], let countryCode = FPNCountryCode(rawValue: code) {

			setFlag(countryCode: countryCode)
		}
	}

	/// Set the country list excluding the provided countries
	open func setCountries(excluding countries: [FPNCountryCode]) {
		countryRepository.setup(without: countries)

		if let selectedCountry = selectedCountry, countryRepository.countries.contains(selectedCountry) {
			fpnDidSelect(country: selectedCountry)
		} else if let country = countryRepository.countries.first {
			fpnDidSelect(country: country)
		}
	}

	/// Set the country list including the provided countries
	open func setCountries(including countries: [FPNCountryCode]) {
		countryRepository.setup(with: countries)

		if let selectedCountry = selectedCountry, countryRepository.countries.contains(selectedCountry) {
			fpnDidSelect(country: selectedCountry)
		} else if let country = countryRepository.countries.first {
			fpnDidSelect(country: country)
		}
	}

	/// Set the country list excluding the provided countries
	@objc open func setCountries(excluding countries: [Int]) {
		let countryCodes: [FPNCountryCode] = countries.compactMap({ index in
			if let key = FPNOBJCCountryKey(rawValue: index), let code = FPNOBJCCountryCode[key], let countryCode = FPNCountryCode(rawValue: code) {
				return countryCode
			}
			return nil
		})

		countryRepository.setup(without: countryCodes)
	}

	/// Set the country list including the provided countries
	@objc open func setCountries(including countries: [Int]) {
		let countryCodes: [FPNCountryCode] = countries.compactMap({ index in
			if let key = FPNOBJCCountryKey(rawValue: index), let code = FPNOBJCCountryCode[key], let countryCode = FPNCountryCode(rawValue: code) {
				return countryCode
			}
			return nil
		})

		countryRepository.setup(with: countryCodes)
	}

	// Private

	@objc private func didEditText() {
		if let phoneCode = selectedCountry?.phoneCode, let number = text {
			var cleanedPhoneNumber = clean(string: number)

			if let validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber) {
				nbPhoneNumber = validPhoneNumber

				cleanedPhoneNumber = validPhoneNumber.nationalNumber.stringValue

				if let inputString = formatter?.inputString(cleanedPhoneNumber) {
					text = remove(dialCode: phoneCode, in: inputString)
				}
				(delegate as? FPNTextFieldDelegate)?.fpnDidValidatePhoneNumber(textField: self, isValid: true)
			} else {
				nbPhoneNumber = nil

				if let dialCode = selectedCountry?.phoneCode {
					if let inputString = formatter?.inputString(cleanedPhoneNumber) {
						text = remove(dialCode: dialCode, in: inputString)
					}
				}
				(delegate as? FPNTextFieldDelegate)?.fpnDidValidatePhoneNumber(textField: self, isValid: false)
			}
		}
	}

	private func convert(format: FPNFormat) -> NBEPhoneNumberFormat {
		switch format {
		case .E164:
			return NBEPhoneNumberFormat.E164
		case .International:
			return NBEPhoneNumberFormat.INTERNATIONAL
		case .National:
			return NBEPhoneNumberFormat.NATIONAL
		case .RFC3966:
			return NBEPhoneNumberFormat.RFC3966
		}
	}

	private func updateUI() {
		if let countryCode = selectedCountry?.code {
			formatter = NBAsYouTypeFormatter(regionCode: countryCode.rawValue)
		}

		//flagButton.setImage(selectedCountry?.flag, for: .normal)
        
        if let selected = selectedCountry {
            phoneCodeLabel.text = "\(selected.code.rawValue) \(selected.phoneCode)"
        }

		if hasPhoneNumberExample == true {
			updatePlaceholder()
		}
		didEditText()
	}

	private func clean(string: String) -> String {
		let allowedCharactersSet = CharacterSet.decimalDigits

		//allowedCharactersSet.insert("+")

		return string.components(separatedBy: allowedCharactersSet.inverted).joined(separator: "")
	}

	private func getWidth(text: String) -> CGFloat {
		if let font = phoneCodeTextField.font {
			let fontAttributes = [NSAttributedString.Key.font: font]
			let size = (text as NSString).size(withAttributes: fontAttributes)

			return size.width.rounded(.up)
		} else {
			phoneCodeTextField.sizeToFit()

			return phoneCodeTextField.frame.size.width.rounded(.up)
		}
	}

	private func getValidNumber(phoneNumber: String) -> NBPhoneNumber? {
		guard let country = selectedCountry else { return nil }

		do {
            let parsedPhoneNumber: NBPhoneNumber = try phoneUtil.parse("\(country.phoneCode)\(phoneNumber)", defaultRegion: country.code.rawValue)
			let isValid = phoneUtil.isValidNumber(parsedPhoneNumber)
			return isValid ? parsedPhoneNumber : nil
		} catch _ {
			return nil
		}
	}

	private func remove(dialCode: String, in phoneNumber: String) -> String {
		return phoneNumber.replacingOccurrences(of: "\(dialCode) ", with: "").replacingOccurrences(of: "\(dialCode)", with: "")
	}

	private func getToolBar(with items: [UIBarButtonItem]) -> UIToolbar {
		let toolbar: UIToolbar = UIToolbar()
		toolbar.barStyle = UIBarStyle.default
		toolbar.items = items
		toolbar.sizeToFit()

		return toolbar
	}

	private func getCountryListBarButtonItems() -> [UIBarButtonItem] {
		let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissCountries))

		doneButton.accessibilityLabel = "doneButton"

		return [space, doneButton]
	}

	private func updatePlaceholder() {
		if let countryCode = selectedCountry?.code {
			do {
				let example = try phoneUtil.getExampleNumber(countryCode.rawValue)
				let phoneNumber = example.nationalNumber.stringValue

				if let inputString = formatter?.inputString(phoneNumber) {
					placeholder = inputString
				} else {
					placeholder = nil
				}
			} catch _ {
				placeholder = nil
			}
		} else {
			placeholder = nil
		}
	}
}
