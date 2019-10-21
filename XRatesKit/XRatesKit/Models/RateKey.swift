struct RateKey {
    let coinCode: String
    let currencyCode: String
}

extension RateKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
    }

    public static func ==(lhs: RateKey, rhs: RateKey) -> Bool {
        lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode
    }

}

extension RateKey: CustomStringConvertible {

    public var description: String {
        "RateKey: [coinCode: \(coinCode); currencyCode: \(currencyCode)]"
    }

}
