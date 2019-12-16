struct PairKey {
    let coinCode: String
    let currencyCode: String
}

extension PairKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
    }

    public static func ==(lhs: PairKey, rhs: PairKey) -> Bool {
        lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode
    }

}

extension PairKey: CustomStringConvertible {

    public var description: String {
        "RateKey: [coinCode: \(coinCode); currencyCode: \(currencyCode)]"
    }

}
