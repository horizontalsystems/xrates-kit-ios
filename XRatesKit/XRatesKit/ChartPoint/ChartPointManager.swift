import RxSwift

class ChartPointManager {
    weak var delegate: IChartPointManagerDelegate?

    private let storage: IChartPointStorage
    private let latestRateManager: ILatestRateManager

    init(storage: IChartPointStorage, latestRateManager: ILatestRateManager) {
        self.storage = storage
        self.latestRateManager = latestRateManager
    }

    private func chartPointsWithLatestRate(chartPoints: [ChartPoint], key: ChartPointKey) -> [ChartPoint] {
        guard let latestRate = latestRateManager.latestRate(key: RateKey(coinCode: key.coinCode, currencyCode: key.currencyCode)) else {
            return chartPoints
        }

        return chartPointsWith(latestRate: latestRate, chartPoints: chartPoints)
    }

    private func chartPointsWith(latestRate: Rate, chartPoints: [ChartPoint]) -> [ChartPoint] {
        guard let lastPoint = chartPoints.last else {
            return chartPoints
        }

        guard lastPoint.date < latestRate.date else {
            return chartPoints
        }

        return chartPoints + [ChartPoint(date: latestRate.date, value: latestRate.value)]
    }

}

extension ChartPointManager: IChartPointManager {

    func lastSyncDate(key: ChartPointKey) -> Date? {
        storage.chartPointRecords(key: key).last?.chartPoint.date
    }

    func chartPoints(key: ChartPointKey) -> [ChartPoint] {
        let chartPoints = storage.chartPointRecords(key: key).map { $0.chartPoint }
        return chartPointsWithLatestRate(chartPoints: chartPoints, key: key)
    }

    func handleUpdated(chartPoints: [ChartPoint], key: ChartPointKey) {
        let records = chartPoints.map {
            ChartPointRecord(key: key, chartPoint: $0)
        }

        storage.deleteChartPointRecords(key: key)
        storage.save(chartPointRecords: records)

        delegate?.didUpdate(chartPoints: chartPointsWithLatestRate(chartPoints: chartPoints, key: key), key: key)
    }

    func handleUpdated(latestRate: Rate, key: ChartPointKey) {
        let chartPoints = storage.chartPointRecords(key: key).map { $0.chartPoint }
        delegate?.didUpdate(chartPoints: chartPointsWith(latestRate: latestRate, chartPoints: chartPoints), key: key)
    }

}
