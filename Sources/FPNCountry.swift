import UIKit

public struct FPNCountry: Equatable {

	public var code: FPNCountryCode
	public var name: String
	public var phoneCode: String

	init(code: String, name: String, phoneCode: String) {
		self.name = name
		self.phoneCode = phoneCode
		self.code = FPNCountryCode(rawValue: code)!
	}

	static public func ==(lhs: FPNCountry, rhs: FPNCountry) -> Bool {
		return lhs.code == rhs.code
	}
}
