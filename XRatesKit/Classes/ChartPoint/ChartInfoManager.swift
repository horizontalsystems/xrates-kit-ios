import RxSwift

class ChartInfoManager {
    weak var delegate: IChartInfoManagerDelegate?

    private let storage: IChartPointStorage
    private let marketInfoManager: IMarketInfoManager

    init(storage: IChartPointStorage, marketInfoManager: IMarketInfoManager) {
        self.storage = storage
        self.marketInfoManager = marketInfoManager
    }

    private func chartInfo(chartPoints: [ChartPoint], key: ChartInfoKey) -> ChartInfo? {
        guard let lastPoint = chartPoints.last else {
            return nil
        }

        let currentTimestamp = Date().timeIntervalSince1970
        let lastPointDiffInterval = currentTimestamp - lastPoint.timestamp
        let startTimestamp = lastPoint.timestamp - key.chartType.rangeInterval

        guard lastPointDiffInterval < key.chartType.rangeInterval else {
            return nil
        }

        guard lastPointDiffInterval < key.chartType.expirationInterval else {
            // expired chart info, current timestamp more than last point
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: startTimestamp,
                    endTimestamp: currentTimestamp
            )
        }

        return ChartInfo(
                points: chartPoints,
                startTimestamp: startTimestamp,
                endTimestamp: lastPoint.timestamp
        )
    }

    private func storedChartPoints(key: ChartInfoKey) -> [ChartPoint] {
        storage.chartPointRecords(key: key).map { $0.chartPoint }
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

        if let chartInfo = chartInfo(chartPoints: chartPoints, key: key) {
            delegate?.didUpdate(chartInfo: chartInfo, key: key)
        } else {
            delegate?.didFoundNoChartInfo(key: key)
        }
    }

    func handleNoChartPoints(key: ChartInfoKey) {
        delegate?.didFoundNoChartInfo(key: key)
    }

}
