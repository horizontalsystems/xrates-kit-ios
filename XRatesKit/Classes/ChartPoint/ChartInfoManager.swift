import RxSwift

class ChartInfoManager {
    weak var delegate: IChartInfoManagerDelegate?

    private let storage: IChartPointStorage
    private let latestRateManager: ILatestRatesManager

    init(storage: IChartPointStorage, latestRateManager: ILatestRatesManager) {
        self.storage = storage
        self.latestRateManager = latestRateManager
    }

    private var utcStartOfToday: Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar.startOfDay(for: Date())
    }

    private func chartInfo(chartPoints: [ChartPoint], key: ChartInfoKey) -> ChartInfo? {
        guard let lastPoint = chartPoints.last else {
            return nil
        }

        let startTimestamp: TimeInterval
        var endTimestamp = Date().timeIntervalSince1970
        let lastPointDiffInterval = endTimestamp - lastPoint.timestamp

        if key.chartType == .today {
            startTimestamp = utcStartOfToday.timeIntervalSince1970
            let day = 24 * 60 * 60
            endTimestamp = startTimestamp + TimeInterval(day)
        } else {
            startTimestamp = lastPoint.timestamp - key.chartType.rangeInterval
        }

        guard lastPointDiffInterval < key.chartType.rangeInterval else {
            return nil
        }

        guard lastPointDiffInterval < key.chartType.expirationInterval else {
            // expired chart info, current timestamp more than last point
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    expired: true
            )
        }

        return ChartInfo(
                points: chartPoints,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                expired: false
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
        var records = chartPoints.map {
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
