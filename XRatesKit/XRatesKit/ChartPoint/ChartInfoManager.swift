import RxSwift

class ChartInfoManager {
    weak var delegate: IChartInfoManagerDelegate?

    private let storage: IChartPointStorage
    private let marketInfoManager: IMarketInfoManager

    init(storage: IChartPointStorage, marketInfoManager: IMarketInfoManager) {
        self.storage = storage
        self.marketInfoManager = marketInfoManager
    }

    private func chartInfo(chartPoints: [ChartPoint], marketInfo: MarketInfo?, key: ChartInfoKey) -> ChartInfo? {
        guard let lastPoint = chartPoints.last else {
            return nil
        }

        let firstPoint = chartPoints[0]

        let currentTimestamp = Date().timeIntervalSince1970
        let lastPointDiffInterval = currentTimestamp - lastPoint.timestamp

        guard lastPointDiffInterval < key.chartType.expirationInterval else {
            // expired chart info, not adding market info point
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: firstPoint.timestamp,
                    endTimestamp: currentTimestamp
            )
        }

        guard let marketInfo = marketInfo, marketInfo.timestamp > lastPoint.timestamp else {
            // non-expired chart info without market info
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: firstPoint.timestamp,
                    endTimestamp: lastPoint.timestamp
            )
        }

        let chartPointsWithMarketInfo = chartPoints + [ChartPoint(timestamp: marketInfo.timestamp, value: marketInfo.rate)]

        return ChartInfo(
                points: chartPointsWithMarketInfo,
                startTimestamp: firstPoint.timestamp,
                endTimestamp: marketInfo.timestamp
        )
    }

    private func chartInfo(chartPoints: [ChartPoint], key: ChartInfoKey) -> ChartInfo? {
        let marketInfo = marketInfoManager.marketInfo(key: PairKey(coinCode: key.coinCode, currencyCode: key.currencyCode))
        return chartInfo(chartPoints: chartPoints, marketInfo: marketInfo, key: key)
    }

    private func storedChartPoints(key: ChartInfoKey) -> [ChartPoint] {
        let currentTimestamp = Date().timeIntervalSince1970
        let fromTimestamp = currentTimestamp - key.chartType.rangeInterval
        let chartPointRecords = storage.chartPointRecords(key: key, fromTimestamp: fromTimestamp)
        return chartPointRecords.map { $0.chartPoint }
    }

    private func notify(chartInfo: ChartInfo?, key: ChartInfoKey) {
        if let chartInfo = chartInfo {
            delegate?.didUpdate(chartInfo: chartInfo, key: key)
        } else {
            delegate?.didFoundNoChartInfo(key: key)
        }
    }

}

extension ChartInfoManager: IChartInfoManager {

    func lastSyncTimestamp(key: ChartInfoKey) -> TimeInterval? {
        storedChartPoints(key: key).last?.timestamp
    }

    func chartInfo(key: ChartInfoKey) -> ChartInfo? {
        chartInfo(chartPoints: storedChartPoints(key: key), key: key)
    }

    func handleUpdated(chartPoints: [ChartPoint], key: ChartInfoKey) {
        let records = chartPoints.map {
            ChartPointRecord(key: key, chartPoint: $0)
        }

        storage.deleteChartPointRecords(key: key)
        storage.save(chartPointRecords: records)

        notify(chartInfo: chartInfo(chartPoints: chartPoints, key: key), key: key)
    }

    func handleUpdated(marketInfo: MarketInfo, key: ChartInfoKey) {
        notify(chartInfo: chartInfo(chartPoints: storedChartPoints(key: key), marketInfo: marketInfo, key: key), key: key)
    }

}
