import RxSwift
import HsToolKit
import CoinKit

public class XRatesKit {
    private let marketInfoManager: IMarketInfoManager
    private let marketInfoSyncManager: IMarketInfoSyncManager
    private let coinMarketsManager: ICoinMarketsManager
    private let globalMarketInfoManager: GlobalMarketInfoManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartInfoManager: IChartInfoManager
    private let chartInfoSyncManager: IChartInfoSyncManager
    private let newsPostsManager: INewsManager

    init(marketInfoManager: IMarketInfoManager, globalMarketInfoManager: GlobalMarketInfoManager, marketInfoSyncManager: IMarketInfoSyncManager,
         coinInfoManager: ICoinMarketsManager, historicalRateManager: IHistoricalRateManager,
         chartInfoManager: IChartInfoManager, chartInfoSyncManager: IChartInfoSyncManager, newsPostsManager: INewsManager) {
        self.globalMarketInfoManager = globalMarketInfoManager
        self.marketInfoManager = marketInfoManager
        self.marketInfoSyncManager = marketInfoSyncManager
        self.coinMarketsManager = coinInfoManager
        self.historicalRateManager = historicalRateManager
        self.chartInfoManager = chartInfoManager
        self.chartInfoSyncManager = chartInfoSyncManager
        self.newsPostsManager = newsPostsManager
    }

}

extension XRatesKit {

    public func refresh() {
        marketInfoSyncManager.refresh()
    }

    public func set(coinTypes: [CoinType]) {
        marketInfoSyncManager.set(coinTypes: coinTypes)
    }

    public func set(currencyCode: String) {
        marketInfoSyncManager.set(currencyCode: currencyCode)
    }

    public func marketInfo(coinType: CoinType, currencyCode: String) -> MarketInfo? {
        marketInfoManager.marketInfo(key: PairKey(coinType: coinType, currencyCode: currencyCode))
    }

    public func marketInfoObservable(coinType: CoinType, currencyCode: String) -> Observable<MarketInfo> {
        marketInfoSyncManager.marketInfoObservable(key: PairKey(coinType: coinType, currencyCode: currencyCode))
    }

    public func marketInfosObservable(currencyCode: String) -> Observable<[CoinType: MarketInfo]> {
        marketInfoSyncManager.marketInfosObservable(currencyCode: currencyCode)
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

    public func chartInfoObservable(coinType: CoinType, currencyCode: String, chartType:ChartType) -> Observable<ChartInfo> {
        chartInfoSyncManager.chartInfoObservable(key: ChartInfoKey(coinType: coinType, currencyCode: currencyCode, chartType: chartType))
    }

    public func cryptoPosts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        newsPostsManager.posts(timestamp: timestamp)
    }

    public var cryptoPostsSingle: Single<[CryptoNewsPost]> {
        newsPostsManager.postsSingle(latestTimestamp: nil)
    }

    public func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, itemsCount: Int = 200) -> Single<[CoinMarket]> {
        coinMarketsManager.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
    }

    public func favorites(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, coinTypes: [CoinType]) -> Single<[CoinMarket]> {
        coinMarketsManager.coinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coinTypes: coinTypes)
    }

    public func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        coinMarketsManager.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
    }

    public func globalMarketInfoSingle(currencyCode: String) -> Single<GlobalCoinMarket> {
        globalMarketInfoManager.globalMarketInfo(currencyCode: currencyCode)
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, coinMarketCapApiKey: String? = nil, cryptoCompareApiKey: String? = nil, uniswapSubgraphUrl: String,
                                indicatorPointCount: Int = 60, marketInfoExpirationInterval: TimeInterval = 60, topMarketsCount: Int = 10,
                                retryInterval: TimeInterval = 30, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let reachabilityManager = ReachabilityManager()

        let storage = GrdbStorage()
        let providerCoinsManager = ProviderCoinsManager(storage: storage, parser: JsonFileParser())

        let networkManager = NetworkManager(logger: logger)
        let coinPaprikaProvider = CoinPaprikaProvider(networkManager: networkManager)
        let cryptoCompareProvider = CryptoCompareProvider(providerCoinsManager: providerCoinsManager, networkManager: networkManager, apiKey: cryptoCompareApiKey, timeoutInterval: 10, expirationInterval: marketInfoExpirationInterval, topMarketsCount: topMarketsCount, indicatorPointCount: indicatorPointCount)
        let uniswapSubgraphProvider = UniswapSubgraphProvider(fiatXRatesProvider: cryptoCompareProvider, networkManager: networkManager, expirationInterval: marketInfoExpirationInterval)
        let baseMarketInfoProvider = BaseMarketInfoProvider(mainProvider: cryptoCompareProvider, uniswapGraphProvider: uniswapSubgraphProvider)

        let horsysProvider = HorsysProvider(networkManager: networkManager)
        let coinGeckoProvider = CoinGeckoProvider(providerCoinsManager: providerCoinsManager, networkManager: networkManager, expirationInterval: marketInfoExpirationInterval)
        let coinGeckoManager = CoinGeckoManager(provider: coinGeckoProvider, storage: storage)

        let marketInfoManager = MarketInfoManager(storage: storage, expirationInterval: marketInfoExpirationInterval)
        let globalMarketInfoManager = GlobalMarketInfoManager(globalMarketInfoProvider: coinPaprikaProvider, defiMarketCapProvider: horsysProvider, storage: storage)

        let marketInfoSchedulerFactory = MarketInfoSchedulerFactory(manager: marketInfoManager, provider: baseMarketInfoProvider, reachabilityManager: reachabilityManager, expirationInterval: marketInfoExpirationInterval, retryInterval: retryInterval, logger: logger)
        let marketInfoSyncManager = MarketInfoSyncManager(currencyCode: currencyCode, schedulerFactory: marketInfoSchedulerFactory)
        marketInfoManager.delegate = marketInfoSyncManager

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: cryptoCompareProvider)

        let chartInfoManager = ChartInfoManager(storage: storage, marketInfoManager: marketInfoManager)
        let chartPointSchedulerFactory = ChartPointSchedulerFactory(manager: chartInfoManager, provider: cryptoCompareProvider, reachabilityManager: reachabilityManager, retryInterval: retryInterval, logger: logger)
        let chartInfoSyncManager = ChartInfoSyncManager(schedulerFactory: chartPointSchedulerFactory, chartInfoManager: chartInfoManager, marketInfoSyncManager: marketInfoSyncManager)

        chartInfoManager.delegate = chartInfoSyncManager

        let newsPostManager = NewsManager(provider: cryptoCompareProvider, state: NewsState(expirationTime: 30 * 60))

        let kit = XRatesKit(
                marketInfoManager: marketInfoManager,
                globalMarketInfoManager: globalMarketInfoManager,
                marketInfoSyncManager: marketInfoSyncManager,
                coinInfoManager: coinGeckoManager,
                historicalRateManager: historicalRateManager,
                chartInfoManager: chartInfoManager,
                chartInfoSyncManager: chartInfoSyncManager,
                newsPostsManager: newsPostManager
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
