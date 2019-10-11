struct ChartStatsSubjectKey {
    let coinCode: String
    let currencyCode: String
    let chartType: ChartType
}

extension ChartStatsSubjectKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
        hasher.combine(chartType)
    }

    public static func ==(lhs: ChartStatsSubjectKey, rhs: ChartStatsSubjectKey) -> Bool {
        lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode && lhs.chartType == rhs.chartType
    }

}
