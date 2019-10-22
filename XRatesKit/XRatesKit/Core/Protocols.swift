import RxSwift

// Latest Rates

protocol ILatestRateManager {
    func lastSyncTimestamp(coinCodes: [String], currencyCode: String) -> TimeInterval?
    func latestRate(key: RateKey) -> Rate?
    func handleUpdated(rates: [LatestRate])
    func notifyExpiredRates(coinCodes: [String], currencyCode: String)
}

protocol ILatestRateManagerDelegate: AnyObject {
    func didUpdate(rateInfo: Rate, key: RateKey)
}

protocol ILatestRateProvider: class {
    func getLatestRates(coinCodes: [String], currencyCode: String) -> Single<[RateResponse]>
}

protocol ILatestRateStorage {
    func latestRate(key: RateKey) -> LatestRate?
    func latestRatesSortedByTimestamp(coinCodes: [String], currencyCode: String) -> [LatestRate]
    func save(latestRates: [LatestRate])
}

protocol ILatestRateSyncManager {
    func set(coinCodes: [String])
    func set(currencyCode: String)
    func refresh()
    func latestRateObservable(key: RateKey) -> Observable<Rate>
}

protocol ILatestRateScheduler {
    func schedule()
    func forceSchedule()
}

protocol ILatestRateSchedulerProvider {
    var lastSyncTimestamp: TimeInterval? { get }
    var expirationInterval: TimeInterval { get }
    var retryInterval: TimeInterval { get }
    var syncSingle: Single<Void> { get }
    func notifyExpiredRates()
}

protocol ILatestRateProviderDelegate: class {
    func didReceive(rate: LatestRate)
    func didSuccess()
    func didFail(error: Error)
}

// Historical Rates

protocol IHistoricalRateManager {
    func historicalRateSingle(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
}

protocol IHistoricalRateProvider {
    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<RateResponse>
}

protocol IHistoricalRateStorage {
    func rate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> HistoricalRate?
    func save(historicalRate: HistoricalRate)
}

// Chart Points

protocol IChartInfoManager {
    func lastSyncTimestamp(key: ChartPointKey) -> TimeInterval?
    func chartInfo(key: ChartPointKey) -> ChartInfo?
    func handleUpdated(chartPoints: [ChartPoint], key: ChartPointKey)
    func handleUpdated(latestRate: Rate, key: ChartPointKey)
}

protocol IChartInfoManagerDelegate: AnyObject {
    func didUpdate(chartInfo: ChartInfo?, key: ChartPointKey)
}

protocol IChartPointProvider {
    func chartPointsSingle(key: ChartPointKey) -> Single<[ChartPoint]>
}

protocol IChartPointStorage {
    func chartPointRecords(key: ChartPointKey, fromTimestamp: TimeInterval) -> [ChartPointRecord]
    func save(chartPointRecords: [ChartPointRecord])
    func deleteChartPointRecords(key: ChartPointKey)
}

protocol IChartInfoSyncManager {
    func chartInfoObservable(key: ChartPointKey) -> Observable<ChartInfo?>
}

protocol IChartPointsScheduler {
    func schedule()
}

protocol IChartPointSchedulerProvider {
    var logKey: String { get }
    var lastSyncTimestamp: TimeInterval? { get }
    var expirationInterval: TimeInterval { get }
    var retryInterval: TimeInterval { get }
    var syncSingle: Single<Void> { get }
}

// Misc

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilityObservable: Observable<Bool> { get }
}

protocol ICurrentDateProvider {
    var currentDate: Date { get }
}

protocol ICryptoCompareFactory {
    func latestRate(coinCode: String, currencyCode: String, response: CryptoCompareLatestRateResponse) -> RateResponse?
    func marketStats(coinCode: String, currencyCode: String, response: CryptoCompareMarketInfoResponse) -> MarketStats?
    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval, value: Decimal) -> RateResponse
}
