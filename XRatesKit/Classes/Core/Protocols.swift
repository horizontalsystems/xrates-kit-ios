import RxSwift
import CoinKit
import Foundation

// Latest Rate

protocol ILatestRatesManager {
    func lastSyncTimestamp(coinTypes: [CoinType], currencyCode: String) -> TimeInterval?
    func latestRate(key: PairKey) -> LatestRate?
    func latestRateMap(coinTypes: [CoinType], currencyCode: String) -> [CoinType: LatestRate]
    func handleUpdated(records: [LatestRateRecord], currencyCode: String)
    func notifyExpired(coinTypes: [CoinType], currencyCode: String)
}

protocol ILatestRatesManagerDelegate: AnyObject {
    var coinTypes: [String: [CoinType]] { get }
    func didUpdate(latestRates: [CoinType: LatestRate], currencyCode: String)
}

protocol ILatestRatesProvider: class {
    func latestRateRecords(coinTypes: [CoinType], currencyCode: String) -> Single<[LatestRateRecord]>
}

protocol ILatestRatesCoinTypeDataSource: AnyObject {
    func coinTypes(currencyCode: String) -> [CoinType]
}

protocol ILatestRatesStorage {
    func latestRateRecord(key: PairKey) -> LatestRateRecord?
    func latestRateRecords(coinTypes: [CoinType], currencyCode: String) -> [LatestRateRecord]
    func latestRateRecordsSortedByTimestamp(coinTypes: [CoinType], currencyCode: String) -> [LatestRateRecord]
    func save(marketInfoRecords: [LatestRateRecord])
}

protocol ILatestRateSyncManager {
    func refresh(currencyCode: String)
    func latestRateObservable(key: PairKey) -> Observable<LatestRate>
    func latestRatesObservable(coinTypes: [CoinType], currencyCode: String) -> Observable<[CoinType: LatestRate]>
}

protocol IScheduler {
    func schedule()
    func forceSchedule()
}

protocol ISchedulerProvider {
    var id: String { get }
    var lastSyncTimestamp: TimeInterval? { get }
    var expirationInterval: TimeInterval { get }
    var retryInterval: TimeInterval { get }
    var syncSingle: Single<Void> { get }
    func notifyExpired()
}

// Top Markets

protocol ITopMarketsStorage {
    func topMarkets(currencyCode: String, limit: Int) -> [(coin: TopMarketCoin, marketInfo: LatestRateRecord)]
    func save(topMarkets: [(coin: TopMarketCoin, marketInfo: LatestRateRecord)])
}

protocol ICoinMarketsManager {
    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int, defiFilter: Bool) -> Single<[CoinMarket]>
    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinTypes: [CoinType], defiFilter: Bool) -> Single<[CoinMarket]>
    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo>
    func coinMarketPointsSingle(coinType: CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[CoinMarketPoint]>
}

protocol ITopMarketsManagerDelegate: AnyObject {
    func didUpdate(topMarketInfos: [MarketInfo])
}

// Global Info

protocol IGlobalCoinMarketProvider {
    func globalCoinMarketPoints(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]>
}

protocol ITokenInfoProvider {
    func topTokenHoldersSingle(coinType: CoinType, itemsCount: Int) -> Single<[TokenHolder]>
}

protocol IDefiMarketsProvider {
    func topDefiTvl(currencyCode: String, timePeriod: TimePeriod, itemCount: Int) -> Single<[DefiTvl]>
    func defiTvl(coinType: CoinType, currencyCode: String) -> Single<DefiTvl?>
    func defiTvlPoints(coinType: CoinType, currencyCode: String, timePeriod: TimePeriod) -> Single<[DefiTvlPoint]>
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

// Coins

protocol ICoinInfoStorage {
    func version(type: DataVersion.DataTypes) -> Int
    var categorizedCoins: [CoinType] { get }
    var coinInfosVersion: Int { get }
    func set(coinInfosVersion: Int)
    func update(coinCategories: [CoinCategory])
    func update(coinFunds: [CoinFund])
    func update(coinFundCategories: [CoinFundCategory])
    func update(coinInfos: [CoinInfoRecord], categoryMaps: [CoinCategoryCoinInfo], fundMaps: [CoinFundCoinInfo], links: [CoinLink])
    func providerCoinInfo(coinType: CoinType) -> (data: CoinData, meta: CoinMeta)?
    func coins(forCategoryId: String) -> [CoinInfoRecord]
}

protocol IProviderCoinsStorage {
    func version(type: DataVersion.DataTypes) -> Int
    func set(version: Int, toType type: DataVersion.DataTypes)
    func update(providerCoins: [ProviderCoinRecord])

    func providerData(id: String, provider: InfoProvider) -> ProviderCoinData?
    func providerId(id: String, provider: InfoProvider) -> String?
    func ids(providerId: String, provider: InfoProvider) -> [String]

    func find(text: String) -> [CoinData]
    func clearPriorities()
    func set(priority: Int, forCoin: CoinType)
}

protocol IGlobalMarketPointInfoStorage {
    func globalMarketPointInfo(currencyCode: String, timePeriod: TimePeriod) -> GlobalCoinMarketInfo?
    func deleteGlobalMarketInfo(currencyCode: String, timePeriod: TimePeriod)
    func saveGlobalMarketInfo(info: GlobalCoinMarketInfo)
}

protocol IExchangeStorage {
    var exchanges: [Exchange] { get }
    func update(exchanges: [Exchange])
}
