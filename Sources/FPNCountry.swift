public struct FPNCountry: Equatable {

	public let code: FPNCountryCode
	public let name: String
	public let phoneCode: String

	static public func ==(lhs: FPNCountry, rhs: FPNCountry) -> Bool {
		return lhs.code == rhs.code
	}
}
