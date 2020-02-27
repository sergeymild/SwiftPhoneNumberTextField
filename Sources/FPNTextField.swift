
import UIKit

open class FPNTextField: UIView {
    private lazy var selectCountryListController: FPNCountryListViewController = {
        let controller = FPNCountryListViewController()
        controller.setup(repository: self.countryRepository)
        controller.didSelect = { [weak self] country in
            self?.setFlag(countryCode: country.code)
        }
        return controller
    }()
    
    let button = UIButton()
    let rightView = UIView()
	public var textField: UITextField = UITextField()

	private lazy var phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
	private var nbPhoneNumber: NBPhoneNumber?
	private var formatter: NBAsYouTypeFormatter?
    
    public let codeLabel = UILabel()
    public let arrowIcon = UIImageView()
    
    public var delegate: FPNTextFieldDelegate? {
        get { (textField.delegate as? FPNTextFieldDelegate) }
        set { textField.delegate = newValue }
    }

	open var font: UIFont? {
		didSet {
			textField.font = font
		}
	}

	open var textColor: UIColor? {
		didSet {
			textField.textColor = textColor
		}
	}

	/// Present in the placeholder an example of a phone number according to the selected country code.
	/// If false, you can set your own placeholder. Set to true by default.
	@objc open var hasPhoneNumberExample: Bool = true {
		didSet {
			if hasPhoneNumberExample == false {
                textField.placeholder = nil
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
		setupFlagButton()
		setupPhoneCodeTextField()
		setupLeftView()

		if let regionCode = Locale.current.regionCode, let countryCode = FPNCountryCode(rawValue: regionCode) {
			setFlag(countryCode: countryCode)
		} else {
			setFlag(countryCode: FPNCountryCode.FR)
		}
	}

	private func setupFlagButton() {
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.image = UIImage(named: "Arrow", in: Bundle.current, compatibleWith: nil)
	}

	private func setupPhoneCodeTextField() {
        addSubview(textField)
        
        textField.keyboardType = .numberPad
        textField.autocorrectionType = .no
        textField.addTarget(
            self,
            action: #selector(didEditText),
            for: .editingChanged
        )
        
		textField.font = font
	}

	private func setupLeftView() {
        addSubview(codeLabel)
        addSubview(arrowIcon)
        addSubview(button)
        button.addTarget(self, action: #selector(displayCountries), for: .touchUpInside)
	}
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let w = codeLabel.intrinsicContentSize.width
        
        codeLabel.frame = .init(x: 0, y: 0, width: w, height: frame.height)
        arrowIcon.frame = .init(x: w + 10, y: 0, width: 12, height: frame.height)
        
        button.frame = .init(
            x: 0,
            y: 0,
            width: codeLabel.frame.width + 20 + 12,
            height: frame.height
        )
        
        textField.frame = .init(
            x: arrowIcon.frame.maxX + 10,
            y: 0,
            width: frame.width - (arrowIcon.frame.maxX + 10),
            height: frame.height)
    }
   
	@objc
    private func displayCountries() {
        delegate?.fpnDisplay(
            selectCountryListController: selectCountryListController
        )
	}

	@objc private func dismissCountries() {
		resignFirstResponder()
        textField.inputView = nil
        textField.inputAccessoryView = nil
		reloadInputViews()
	}

	private func fpnDidSelect(country: FPNCountry) {
        delegate?.fpnDidSelectCountry?(
            name: country.name,
            dialCode: country.phoneCode,
            code: country.code.rawValue
        )
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
                textField.text = "0\(validPhoneNumber.nationalNumber.stringValue)"
			} else {
                textField.text = validPhoneNumber.nationalNumber.stringValue
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

	@objc private func didEditText() {
        if let phoneCode = selectedCountry?.phoneCode, let number = textField.text {
			var cleanedPhoneNumber = clean(string: number)

			if let validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber) {
				nbPhoneNumber = validPhoneNumber

				cleanedPhoneNumber = validPhoneNumber.nationalNumber.stringValue

				if let inputString = formatter?.inputString(cleanedPhoneNumber) {
                    textField.text = remove(dialCode: phoneCode, in: inputString)
				}
                delegate?.fpnDidValidatePhoneNumber(isValid: true)
			} else {
				nbPhoneNumber = nil

				if let dialCode = selectedCountry?.phoneCode {
					if let inputString = formatter?.inputString(cleanedPhoneNumber) {
                        textField.text = remove(dialCode: dialCode, in: inputString)
					}
				}
                delegate?.fpnDidValidatePhoneNumber(isValid: false)
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
            codeLabel.text = "\(selected.code.rawValue) \(selected.phoneCode)"
            layoutSubviews()
        }

		if hasPhoneNumberExample == true {
			updatePlaceholder()
		}
		didEditText()
	}

	private func clean(string: String) -> String {
		let allowedCharactersSet = CharacterSet.decimalDigits
		return string.components(
            separatedBy: allowedCharactersSet.inverted
        ).joined(separator: "")
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
                    textField.placeholder = inputString
				} else {
                    textField.placeholder = nil
				}
			} catch _ {
                textField.placeholder = nil
			}
		} else {
            textField.placeholder = nil
		}
	}
}
