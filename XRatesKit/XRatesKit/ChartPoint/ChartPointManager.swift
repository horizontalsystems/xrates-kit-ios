import RxSwift

class ChartPointManager {
    weak var delegate: IChartPointManagerDelegate?

    private let storage: IChartPointStorage

    init(storage: IChartPointStorage) {
        self.storage = storage
    }

}

extension ChartPointManager: IChartPointManager {

    func lastSyncDate(key: ChartPointKey) -> Date? {
        storage.chartPointRecords(key: key).last?.chartPoint.date
    }

    func chartPoints(key: ChartPointKey) -> [ChartPoint] {
        storage.chartPointRecords(key: key).map { $0.chartPoint }
    }

    func handleUpdated(chartPoints: [ChartPoint], key: ChartPointKey) {
        let records = chartPoints.map {
            ChartPointRecord(key: key, chartPoint: $0)
        }

        storage.deleteChartPointRecords(key: key)
        storage.save(chartPointRecords: records)

        delegate?.didUpdate(chartPoints: chartPoints, key: key)
    }

}
