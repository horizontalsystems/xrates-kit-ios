import CoinKit

struct PairKey {
    let coinType: CoinType
    let currencyCode: String
}

extension PairKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinType)
        hasher.combine(currencyCode)
    }

    public static func ==(lhs: PairKey, rhs: PairKey) -> Bool {
        lhs.coinType == rhs.coinType && lhs.currencyCode == rhs.currencyCode
    }

}

extension PairKey: CustomStringConvertible {

    public var description: String {
        "RateKey: [coinType: \(coinType); currencyCode: \(currencyCode)]"
    }

}
