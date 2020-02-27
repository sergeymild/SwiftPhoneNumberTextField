
import Foundation

public extension Bundle {

	static let current = getLibraryBundle()

	static func getLibraryBundle() -> Bundle {
		let bundle = Bundle(for: FPNTextField.self)

		if let path = bundle.path(forResource: "FlagPhoneNumber", ofType: "bundle") {
			return Bundle(path: path)!
		} else {
			return bundle
		}
	}
}
