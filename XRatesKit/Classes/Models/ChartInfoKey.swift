struct ChartInfoKey {
    let coinCode: String
    let currencyCode: String
    let chartType: ChartType
}

extension ChartInfoKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
        hasher.combine(chartType)
    }

    public static func ==(lhs: ChartInfoKey, rhs: ChartInfoKey) -> Bool {
        lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode && lhs.chartType == rhs.chartType
    }

}

extension ChartInfoKey: CustomStringConvertible {

    public var description: String {
        "[\(coinCode); \(currencyCode); \(chartType)]"
    }

}
