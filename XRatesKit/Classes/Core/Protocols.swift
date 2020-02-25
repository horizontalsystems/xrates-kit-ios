import RxSwift

// Market Info

protocol IMarketInfoManager {
    func lastSyncTimestamp(coinCodes: [String], currencyCode: String) -> TimeInterval?
    func marketInfo(key: PairKey) -> MarketInfo?
    func handleUpdated(records: [MarketInfoRecord], currencyCode: String)
    func notifyExpired(coinCodes: [String], currencyCode: String)
}

protocol IMarketInfoManagerDelegate: AnyObject {
    func didUpdate(marketInfo: MarketInfo, key: PairKey)
    func didUpdate(marketInfos: [String: MarketInfo], currencyCode: String)
}

protocol IMarketInfoProvider: class {
    func getMarketInfoRecords(coinCodes: [String], currencyCode: String) -> Single<[MarketInfoRecord]>
}

protocol IMarketInfoStorage {
    func marketInfoRecord(key: PairKey) -> MarketInfoRecord?
    func marketInfoRecordsSortedByTimestamp(coinCodes: [String], currencyCode: String) -> [MarketInfoRecord]
    func save(marketInfoRecords: [MarketInfoRecord])
}

protocol IMarketInfoSyncManager {
    func set(coinCodes: [String])
    func set(currencyCode: String)
    func refresh()
    func marketInfoObservable(key: PairKey) -> Observable<MarketInfo>
    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]>
}

protocol IMarketInfoScheduler {
    func schedule()
    func forceSchedule()
}

protocol IMarketInfoSchedulerProvider {
    var lastSyncTimestamp: TimeInterval? { get }
    var expirationInterval: TimeInterval { get }
    var retryInterval: TimeInterval { get }
    var syncSingle: Single<Void> { get }
    func notifyExpired()
}

// Historical Rates

protocol IHistoricalRateManager {
    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Decimal?
    func historicalRateSingle(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
}

protocol IHistoricalRateProvider {
    func getHistoricalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
}

protocol IHistoricalRateStorage {
    func rate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> HistoricalRate?
    func save(historicalRate: HistoricalRate)
}

// Chart Points

protocol IChartInfoManager {
    func lastSyncTimestamp(key: ChartInfoKey) -> TimeInterval?
    func chartInfo(key: ChartInfoKey) -> ChartInfo?
    func handleUpdated(chartPoints: [ChartPoint], key: ChartInfoKey)
    func handleNoChartPoints(key: ChartInfoKey)
    func handleUpdated(marketInfo: MarketInfo, key: ChartInfoKey)
}

protocol IChartInfoManagerDelegate: AnyObject {
    func didUpdate(chartInfo: ChartInfo, key: ChartInfoKey)
    func didFoundNoChartInfo(key: ChartInfoKey)
}

protocol IChartPointProvider {
    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]>
}

protocol IChartPointStorage {
    func chartPointRecords(key: ChartInfoKey, fromTimestamp: TimeInterval) -> [ChartPointRecord]
    func save(chartPointRecords: [ChartPointRecord])
    func deleteChartPointRecords(key: ChartInfoKey)
}

protocol IChartInfoSyncManager {
    func chartInfoObservable(key: ChartInfoKey) -> Observable<ChartInfo>
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

// News Posts

protocol INewsProvider {
    func newsSingle(for categories: String, latestTimestamp: TimeInterval?) -> Single<CryptoCompareNewsResponse>
}

protocol INewsManager {
    func posts(for coinName: String, timestamp: TimeInterval) -> [CryptoNewsPost]
    func postsSingle(for coinName: String, latestTimestamp: TimeInterval?) -> Single<[CryptoNewsPost]>
}

protocol INewsState {
    func set(posts: [CryptoNewsPost], coinName: String)
    func nonExpiredPosts(for coinName: String, timestamp: TimeInterval) -> [CryptoNewsPost]
}

// Misc

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilityObservable: Observable<Bool> { get }
}
