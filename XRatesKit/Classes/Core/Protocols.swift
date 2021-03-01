import RxSwift
import CoinKit

// Market Info

protocol IMarketInfoManager {
    func lastSyncTimestamp(coinTypes: [CoinType], currencyCode: String) -> TimeInterval?
    func marketInfo(key: PairKey) -> MarketInfo?
    func handleUpdated(records: [MarketInfoRecord], currencyCode: String)
    func notifyExpired(coinTypes: [CoinType], currencyCode: String)
}

protocol IMarketInfoManagerDelegate: AnyObject {
    func didUpdate(marketInfo: MarketInfo, key: PairKey)
    func didUpdate(marketInfos: [CoinType: MarketInfo], currencyCode: String)
}

protocol IMarketInfoProvider: class {
    func marketInfoRecords(coinTypes: [CoinType], currencyCode: String) -> Single<[MarketInfoRecord]>
}

protocol IMarketInfoStorage {
    func marketInfoRecord(key: PairKey) -> MarketInfoRecord?
    func marketInfoRecordsSortedByTimestamp(coinTypes: [CoinType], currencyCode: String) -> [MarketInfoRecord]
    func save(marketInfoRecords: [MarketInfoRecord])
}

protocol IMarketInfoSyncManager {
    func set(coinTypes: [CoinType])
    func set(currencyCode: String)
    func refresh()
    func marketInfoObservable(key: PairKey) -> Observable<MarketInfo>
    func marketInfosObservable(currencyCode: String) -> Observable<[CoinType: MarketInfo]>
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

// Top Markets

protocol ITopMarketsStorage {
    func topMarkets(currencyCode: String, limit: Int) -> [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]
    func save(topMarkets: [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)])
}

protocol ICoinMarketsManager {
    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]>
    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinTypes: [CoinType]) -> Single<[CoinMarket]>
    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo>
}

protocol ITopMarketsManagerDelegate: AnyObject {
    func didUpdate(topMarketInfos: [MarketInfo])
}

// Global Info

protocol IGlobalMarketInfoProvider {
    func globalCoinMarketsInfo(currencyCode: String) -> Single<GlobalCoinMarket>
}

// Historical Rates

protocol IHistoricalRateManager {
    func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal?
    func historicalRateSingle(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
}

protocol IHistoricalRateProvider {
    func getHistoricalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
}

protocol IHistoricalRateStorage {
    func rate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> HistoricalRate?
    func save(historicalRate: HistoricalRate)
}

protocol IGlobalMarketInfoStorage {
    func save(globalMarketInfo: GlobalCoinMarket)
    func globalMarketInfo(currencyCode: String) -> GlobalCoinMarket?
}

// Chart Points

protocol IChartInfoManager {
    func lastSyncTimestamp(key: ChartInfoKey) -> TimeInterval?
    func chartInfo(key: ChartInfoKey) -> ChartInfo?
    func handleUpdated(chartPoints: [ChartPoint], key: ChartInfoKey)
    func handleNoChartPoints(key: ChartInfoKey)
}

protocol IChartInfoManagerDelegate: AnyObject {
    func didUpdate(chartInfo: ChartInfo, key: ChartInfoKey)
    func didFoundNoChartInfo(key: ChartInfoKey)
}

protocol IChartPointProvider {
    func chartPointsSingle(key: ChartInfoKey) -> Single<[ChartPoint]>
}

protocol IChartPointStorage {
    func chartPointRecords(key: ChartInfoKey) -> [ChartPointRecord]
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
    func newsSingle(latestTimestamp: TimeInterval?) -> Single<CryptoCompareNewsResponse>
}

protocol INewsManager {
    func posts(timestamp: TimeInterval) -> [CryptoNewsPost]?
    func postsSingle(latestTimestamp: TimeInterval?) -> Single<[CryptoNewsPost]>
}

protocol INewsState {
    func set(posts: [CryptoNewsPost])
    func nonExpiredPosts(timestamp: TimeInterval) -> [CryptoNewsPost]?
}


// Fiat Exchange Rates

protocol IFiatXRatesProvider {
    func latestFiatXRates(sourceCurrency: String, targetCurrency: String) -> Single<Decimal>
}

// Coins

protocol ICoinInfoStorage {
    var coinInfosVersion: Int { get }
    func set(coinInfosVersion: Int)
    func update(coinCategories: [CoinCategory])
    func update(coinInfos: [CoinInfoRecord], categoryMaps: [CoinCategoryCoinInfo], links: [CoinLink])
    func providerCoinInfo(coinType: CoinType) -> (data: CoinData, meta: CoinMeta)?
}

protocol IProviderCoinsStorage {
    var providerCoinsVersion: Int { get }
    func set(providerCoinsVersion: Int)
    func update(providerCoins: [ProviderCoinRecord])
    func providerId(id: String, provider: InfoProvider) -> String?
    func id(providerId: String, provider: InfoProvider) -> String?
}
