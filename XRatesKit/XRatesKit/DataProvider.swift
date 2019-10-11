import RxSwift

class DataProvider {
    private let storage: ILatestRateStorage & IChartStatsStorage
    private let subjectsHolder: ISubjectsHolder
    private let historicalRateManager: IHistoricalRateManager
    private let chartStatsSyncer: IChartStatsSyncer
    private let factory: IDataProviderFactory

    init(storage: ILatestRateStorage & IChartStatsStorage, subjectsHolder: ISubjectsHolder, historicalRateManager: IHistoricalRateManager, chartStatsSyncer: IChartStatsSyncer, factory: IDataProviderFactory) {
        self.storage = storage
        self.subjectsHolder = subjectsHolder
        self.historicalRateManager = historicalRateManager
        self.chartStatsSyncer = chartStatsSyncer
        self.factory = factory
    }

    private func chartPointsWithLatestRate(chartStatList: [ChartStats], latestRate: Rate?) -> [ChartPoint] {
        let chartPoints = chartStatList.map { factory.chartPoint($0) }
        guard let latestRate = latestRate, let lastPoint = chartPoints.last else {
            return chartPoints
        }
        guard latestRate.date.timeIntervalSince1970 > lastPoint.timestamp else {
            return chartPoints
        }
        return chartPoints + [factory.chartPoint(timestamp: latestRate.date.timeIntervalSince1970, value: latestRate.value)]
    }

}

extension DataProvider: IDataProvider {

    func latestRate(coinCode: String, currencyCode: String) -> RateInfo? {
        storage.latestRate(coinCode: coinCode, currencyCode: currencyCode).map { factory.rateInfo($0) }
    }

    func historicalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        historicalRateManager.getHistoricalRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
    }

    func chartPoints(coinCode: String, currencyCode: String, chartType: ChartType) -> [ChartPoint] {
        let chartStatList = storage.chartStatList(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
        if let last = chartStatList.last, last.timestamp < 0 {
            chartStatsSyncer.syncChartStats(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
        }

        let latestRate = storage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
        let chartPoints = chartPointsWithLatestRate(chartStatList: chartStatList, latestRate: latestRate)

        return chartPoints
    }

}

extension DataProvider: IChartStatsManagerDelegate {

    func didUpdate(chartStatList: [ChartStats], coinCode: String, currencyCode: String, chartType: ChartType) {
        let key = ChartStatsSubjectKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
        guard let subject = subjectsHolder.chartStatsSubjects[key], !chartStatList.isEmpty else {
            return
        }
        let latestRate = storage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
        let chartPoints = chartPointsWithLatestRate(chartStatList: chartStatList, latestRate: latestRate)
        subject.onNext(chartPoints)
    }

}

extension DataProvider: ILatestRateSyncerDelegate {

    func didUpdate(rate: Rate) {
        let key = RateSubjectKey(coinCode: rate.coinCode, currencyCode: rate.currencyCode)
        subjectsHolder.latestRateSubjects[key]?.onNext(factory.rateInfo(rate))

        subjectsHolder.activeChartStatsKeys
                .filter { key in key.coinCode == rate.coinCode && key.currencyCode == rate.currencyCode }
                .forEach { key in
            let chartStatList = storage.chartStatList(coinCode: key.coinCode, currencyCode: key.currencyCode, chartType: key.chartType)
            guard !chartStatList.isEmpty else {
                return
            }
            let chartPoints = chartPointsWithLatestRate(chartStatList: chartStatList, latestRate: rate)
            subjectsHolder.chartStatsSubjects[key]?.onNext(chartPoints)
        }
    }

}