import RxSwift

class ChartInfoManager {
    weak var delegate: IChartInfoManagerDelegate?

    private let storage: IChartPointStorage
    private let latestRateManager: ILatestRateManager

    init(storage: IChartPointStorage, latestRateManager: ILatestRateManager) {
        self.storage = storage
        self.latestRateManager = latestRateManager
    }

    private func chartInfo(chartPoints: [ChartPoint], latestRate: Rate?, key: ChartPointKey) -> ChartInfo? {
        guard let lastPoint = chartPoints.last else {
            return nil
        }

        let firstPoint = chartPoints[0]

        let currentTimestamp = Date().timeIntervalSince1970
        let lastPointDiffInterval = currentTimestamp - lastPoint.timestamp

        guard lastPointDiffInterval < key.chartType.expirationInterval else {
            // expired chart info, not adding latest rate point
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: firstPoint.timestamp,
                    endTimestamp: currentTimestamp,
                    diff: nil
            )
        }

        guard let latestRate = latestRate, latestRate.timestamp > lastPoint.timestamp else {
            // non-expired chart info without latest rate
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: firstPoint.timestamp,
                    endTimestamp: lastPoint.timestamp,
                    diff: nil
            )
        }

        let chartPointsWithLatestRate = chartPoints + [ChartPoint(timestamp: latestRate.timestamp, value: latestRate.value)]
        var diff: Decimal? = nil

        if !latestRate.expired {
            diff = (latestRate.value - firstPoint.value) / firstPoint.value * 100
        }

        return ChartInfo(
                points: chartPointsWithLatestRate,
                startTimestamp: firstPoint.timestamp,
                endTimestamp: latestRate.timestamp,
                diff: diff
        )
    }

    private func chartInfo(chartPoints: [ChartPoint], key: ChartPointKey) -> ChartInfo? {
        let latestRate = latestRateManager.latestRate(key: RateKey(coinCode: key.coinCode, currencyCode: key.currencyCode))
        return chartInfo(chartPoints: chartPoints, latestRate: latestRate, key: key)
    }

    private func storedChartPoints(key: ChartPointKey) -> [ChartPoint] {
        let currentTimestamp = Date().timeIntervalSince1970
        let fromTimestamp = currentTimestamp - key.chartType.rangeInterval
        let chartPointRecords = storage.chartPointRecords(key: key, fromTimestamp: fromTimestamp)
        return chartPointRecords.map { $0.chartPoint }
    }

}

extension ChartInfoManager: IChartInfoManager {

    func lastSyncTimestamp(key: ChartPointKey) -> TimeInterval? {
        storedChartPoints(key: key).last?.timestamp
    }

    func chartInfo(key: ChartPointKey) -> ChartInfo? {
        chartInfo(chartPoints: storedChartPoints(key: key), key: key)
    }

    func handleUpdated(chartPoints: [ChartPoint], key: ChartPointKey) {
        let records = chartPoints.map {
            ChartPointRecord(key: key, chartPoint: $0)
        }

        storage.deleteChartPointRecords(key: key)
        storage.save(chartPointRecords: records)

        delegate?.didUpdate(chartInfo: chartInfo(chartPoints: chartPoints, key: key), key: key)
    }

    func handleUpdated(latestRate: Rate, key: ChartPointKey) {
        delegate?.didUpdate(chartInfo: chartInfo(chartPoints: storedChartPoints(key: key), latestRate: latestRate, key: key), key: key)
    }

}
