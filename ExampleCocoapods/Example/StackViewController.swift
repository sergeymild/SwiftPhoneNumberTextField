
import UIKit
import FlagPhoneNumber

class StackViewController: UIViewController {

	lazy var phoneEditTextField: FPNTextField = {
        let editText = FPNTextField()
        editText.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        editText.hasPhoneNumberExample = true
        editText.codeLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        editText.delegate = self

        
        
        return editText
    }()

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "In Stack View"
		view.backgroundColor = UIColor.groupTableViewBackground
        view.addSubview(phoneEditTextField)
		//phoneEditTextField.delegate = self
	}
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        phoneEditTextField.frame = .init(x: 16, y: 100, width: view.frame.width - 32, height: 72)
    }

}

extension StackViewController: FPNTextFieldDelegate {

    func fpnDisplay(selectCountryListController: UIViewController) {
        navigationController?.pushViewController(selectCountryListController, animated: true)
    }

	func fpnDidValidatePhoneNumber(isValid: Bool) {
		//textField.rightViewMode = .always
		//textField.rightView = UIImageView(image: isValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "error"))

        print(isValid, phoneEditTextField.getRawPhoneNumber(shouldIncludeCode: true))
	}

	func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
		print(name, dialCode, code)
	}
}
