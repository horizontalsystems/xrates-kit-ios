struct ChartPointKey {
    let coinCode: String
    let currencyCode: String
    let chartType: ChartType
}

extension ChartPointKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
        hasher.combine(chartType)
    }

    public static func ==(lhs: ChartPointKey, rhs: ChartPointKey) -> Bool {
        lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode && lhs.chartType == rhs.chartType
    }

}

extension ChartPointKey: CustomStringConvertible {

    public var description: String {
        "[\(coinCode); \(currencyCode); \(chartType)]"
    }

}
