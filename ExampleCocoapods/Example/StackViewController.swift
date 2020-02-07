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

	@IBOutlet weak var phoneNumberTextField: FPNTextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "In Stack View"
		view.backgroundColor = UIColor.groupTableViewBackground

        //phoneNumberTextField.flagButton.setTitleColor(.black, for: .normal)
        phoneNumberTextField.letfImageView.image = UIImage(named: "Arrow")
		phoneNumberTextField.displayMode = .picker
		phoneNumberTextField.delegate = self
	}

}

extension StackViewController: FPNTextFieldDelegate {

	func fpnDisplayCountryList() {}

	func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
		textField.rightViewMode = .always
		textField.rightView = UIImageView(image: isValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "error"))

		print(isValid)
	}

	func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
		print(name, dialCode, code)
	}
}
