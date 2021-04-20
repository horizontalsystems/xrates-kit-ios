import RxSwift
import HsToolKit
import CoinKit

public class XRatesKit {
    private let latestRateManager: ILatestRatesManager
    private let latestRateSyncManager: ILatestRateSyncManager
    private let coinMarketsManager: ICoinMarketsManager
    private let globalMarketInfoManager: GlobalMarketInfoManager
    private let defiMarketsManager: DefiMarketManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartInfoManager: IChartInfoManager
    private let chartInfoSyncManager: IChartInfoSyncManager
    private let newsPostsManager: INewsManager
    private let coinInfoManager: CoinInfoManager
    private let providerCoinsManager: ProviderCoinsManager
    private let coinSyncer: CoinSyncer

    init(latestRateManager: ILatestRatesManager, globalMarketInfoManager: GlobalMarketInfoManager, defiMarketsManager: DefiMarketManager,
         latestRateSyncManager: ILatestRateSyncManager, coinMarketsManager: ICoinMarketsManager, historicalRateManager: IHistoricalRateManager,
         chartInfoManager: IChartInfoManager, chartInfoSyncManager: IChartInfoSyncManager, newsPostsManager: INewsManager,
         coinInfoManager: CoinInfoManager, providerCoinsManager: ProviderCoinsManager, coinSyncer: CoinSyncer) {
        self.globalMarketInfoManager = globalMarketInfoManager
        self.defiMarketsManager = defiMarketsManager
        self.latestRateManager = latestRateManager
        self.latestRateSyncManager = latestRateSyncManager
        self.coinMarketsManager = coinMarketsManager
        self.historicalRateManager = historicalRateManager
        self.chartInfoManager = chartInfoManager
        self.chartInfoSyncManager = chartInfoSyncManager
        self.newsPostsManager = newsPostsManager
        self.coinInfoManager = coinInfoManager
        self.providerCoinsManager = providerCoinsManager
        self.coinSyncer = coinSyncer
    }

}

extension XRatesKit {

    public func refresh(currencyCode: String) {
        latestRateSyncManager.refresh(currencyCode: currencyCode)
    }

    public func latestRate(coinType: CoinType, currencyCode: String) -> LatestRate? {
        latestRateManager.latestRate(key: PairKey(coinType: coinType, currencyCode: currencyCode))
    }

    public func latestRateObservable(coinType: CoinType, currencyCode: String) -> Observable<LatestRate> {
        latestRateSyncManager.latestRateObservable(key: PairKey(coinType: coinType, currencyCode: currencyCode))
    }

    public func latestRatesObservable(coinTypes: [CoinType], currencyCode: String) -> Observable<[CoinType: LatestRate]> {
        latestRateSyncManager.latestRatesObservable(coinTypes: coinTypes, currencyCode: currencyCode)
    }

    public func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        historicalRateManager.historicalRate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
    }

    public func historicalRateSingle(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        historicalRateManager.historicalRateSingle(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
    }

    public func chartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        chartInfoManager.chartInfo(key: ChartInfoKey(coinType: coinType, currencyCode: currencyCode, chartType: chartType))
    }

    public func chartInfoObservable(coinType: CoinType, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo> {
        chartInfoSyncManager.chartInfoObservable(key: ChartInfoKey(coinType: coinType, currencyCode: currencyCode, chartType: chartType))
    }

    public func cryptoPosts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        newsPostsManager.posts(timestamp: timestamp)
    }

    public var cryptoPostsSingle: Single<[CryptoNewsPost]> {
        newsPostsManager.postsSingle(latestTimestamp: nil)
    }

    public func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, itemsCount: Int = 200) -> Single<[CoinMarket]> {
        coinMarketsManager.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount, defiFilter: false)
    }

    public func favorites(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, coinTypes: [CoinType]) -> Single<[CoinMarket]> {
        coinMarketsManager.coinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coinTypes: coinTypes, defiFilter: false)
    }

    public func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        coinMarketsManager.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
    }

    public func coinTypes(forCategoryId categoryId: String) -> [CoinType] {
        coinInfoManager.coinTypes(forCategoryId: categoryId)
    }

    public func globalMarketInfoSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<GlobalCoinMarket> {
        globalMarketInfoManager.globalMarketInfo(currencyCode: currencyCode, timePeriod: timePeriod)
    }

    public func globalMarketInfoPointsSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]> {
        globalMarketInfoManager.globalMarketInfoPoints(currencyCode: currencyCode, timePeriod: timePeriod)
    }

    public func topDefiMarkets(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, itemsCount: Int = 200) -> Single<[CoinMarket]> {
        defiMarketsManager.topDefiMarkets(currency: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
}

    public func topDefiTvl(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, itemsCount: Int = 200) -> Single<[DefiTvl]> {
        defiMarketsManager.topDefiTvl(currency: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
    }


public func search(text: String) -> [CoinData] {
        providerCoinsManager.search(text: text)
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, coinMarketCapApiKey: String? = nil, cryptoCompareApiKey: String? = nil, uniswapSubgraphUrl: String,
                                indicatorPointCount: Int = 60, marketInfoExpirationInterval: TimeInterval = 60, topMarketsCount: Int = 10,
                                retryInterval: TimeInterval = 30, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)
        let reachabilityManager = ReachabilityManager()
        let storage = GrdbStorage()

        let jsonParser = JsonFileParser()
        let providerCoinsManager = ProviderCoinsManager(storage: storage, parser: jsonParser)
        let coinInfoManager = CoinInfoManager(storage: storage, parser: jsonParser)

        let networkManager = NetworkManager(logger: logger)
        let coinGeckoProvider = CoinGeckoProvider(providerCoinsManager: providerCoinsManager, expirationInterval: marketInfoExpirationInterval, logger: logger)

        let horsysProvider = HorsysProvider(networkManager: networkManager, providerCoinsManager: providerCoinsManager)
        let coinGeckoManager = CoinGeckoManager(coinInfoManager: coinInfoManager, provider: coinGeckoProvider)

        let latestRatesManager = LatestRatesManager(storage: storage, expirationInterval: marketInfoExpirationInterval)
        let globalMarketInfoManager = GlobalMarketInfoManager(globalMarketInfoProvider: horsysProvider, storage: storage)

        let defiMarketsManager = DefiMarketManager(coinGeckoProvider: coinGeckoProvider, defiMarketsProvider: horsysProvider)

        let latestRatesSchedulerFactory = LatestRatesSchedulerFactory(manager: latestRatesManager, provider: coinGeckoProvider, reachabilityManager: reachabilityManager, expirationInterval: marketInfoExpirationInterval, retryInterval: retryInterval, logger: logger)
        let latestRatesSyncManager = LatestRatesSyncManager(schedulerFactory: latestRatesSchedulerFactory)
        latestRatesManager.delegate = latestRatesSyncManager

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: coinGeckoProvider)

        let chartInfoManager = ChartInfoManager(storage: storage, latestRateManager: latestRatesManager)
        let chartPointSchedulerFactory = ChartPointSchedulerFactory(manager: chartInfoManager, provider: coinGeckoProvider, reachabilityManager: reachabilityManager, retryInterval: retryInterval, logger: logger)
        let chartInfoSyncManager = ChartInfoSyncManager(schedulerFactory: chartPointSchedulerFactory, chartInfoManager: chartInfoManager, marketInfoSyncManager: latestRatesSyncManager)

        chartInfoManager.delegate = chartInfoSyncManager
        providerCoinsManager.provider = coinGeckoProvider

        let newsPostManager = NewsManager(provider: NewsProvider(), state: NewsState(expirationTime: 30 * 60))
        let coinSyncer = CoinSyncer(providerCoinsManager: providerCoinsManager, coinInfoManager: coinInfoManager)

        let kit = XRatesKit(
                latestRateManager: latestRatesManager,
                globalMarketInfoManager: globalMarketInfoManager,
                defiMarketsManager: defiMarketsManager,
                latestRateSyncManager: latestRatesSyncManager,
                coinMarketsManager: coinGeckoManager,
                historicalRateManager: historicalRateManager,
                chartInfoManager: chartInfoManager,
                chartInfoSyncManager: chartInfoSyncManager,
                newsPostsManager: newsPostManager,
                coinInfoManager: coinInfoManager,
                providerCoinsManager: providerCoinsManager,
                coinSyncer: coinSyncer
        )

        return kit
    }

    private static func databaseDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("xrates-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}
