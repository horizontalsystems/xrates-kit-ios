import CoinKit

struct ChartInfoKey {
    let coinType: CoinType
    let currencyCode: String
    let chartType: ChartType
}

extension ChartInfoKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinType)
        hasher.combine(currencyCode)
        hasher.combine(chartType)
    }

    public static func ==(lhs: ChartInfoKey, rhs: ChartInfoKey) -> Bool {
        lhs.coinType == rhs.coinType && lhs.currencyCode == rhs.currencyCode && lhs.chartType == rhs.chartType
    }

}

extension ChartInfoKey: CustomStringConvertible {

    public var description: String {
        "[\(coinType); \(currencyCode); \(chartType)]"
    }

}
