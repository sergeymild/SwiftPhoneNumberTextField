
import UIKit
@objc
public protocol FPNTextFieldDelegate: UITextFieldDelegate {
    @objc
    optional func fpnDidSelectCountry(name: String, dialCode: String, code: String)
	func fpnDidValidatePhoneNumber(isValid: Bool)
    func fpnDisplay(selectCountryListController: UIViewController)
}
