//
//  StackViewController.swift
//  FlagPhoneNumber_Example
//
//  Created by Aurelien on 24/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import FlagPhoneNumber

class StackViewController: UIViewController {
    
    var listController = FPNCountryListViewController(style: .grouped)

	lazy var phoneEditTextField: FPNTextField = {
        let editText = FPNTextField()
        editText.hasPhoneNumberExample = true
        editText.delegate = self
        
        listController.setup(repository: editText.countryRepository)
        listController.didSelect = { country in
            editText.setFlag(countryCode: country.code)
        }
        
        return editText
    }()

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "In Stack View"
		view.backgroundColor = UIColor.groupTableViewBackground
        view.addSubview(phoneEditTextField)
		phoneEditTextField.delegate = self
	}
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        phoneEditTextField.frame = .init(x: 16, y: 100, width: view.frame.width - 32, height: 72)
    }

}

extension StackViewController: FPNTextFieldDelegate {

	func fpnDisplayCountryList() {
        let navigationViewController = UINavigationController(rootViewController: listController)
        present(navigationViewController, animated: true, completion: nil)
    }

	func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
		textField.rightViewMode = .always
		textField.rightView = UIImageView(image: isValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "error"))

		print(isValid)
	}

	func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
		print(name, dialCode, code)
	}
}
