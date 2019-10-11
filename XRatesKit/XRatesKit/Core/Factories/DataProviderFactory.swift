import Foundation

class DataProviderFactory: IDataProviderFactory {

    func rateInfo(_ rate: Rate) -> RateInfo {
        RateInfo(rate)
    }

    func chartPoint(_ chartStats: ChartStats) -> ChartPoint {
        ChartPoint(timestamp: chartStats.timestamp, value: chartStats.value)
    }

    func chartPoint(timestamp: TimeInterval, value: Decimal) -> ChartPoint {
        ChartPoint(timestamp: timestamp, value: value)
    }

}
