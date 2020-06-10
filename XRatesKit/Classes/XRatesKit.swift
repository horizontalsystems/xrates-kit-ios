import RxSwift
import HsToolKit

public class XRatesKit {
    private let marketInfoManager: IMarketInfoManager
    private let topMarketsManager: ITopMarketsManager
    private let marketInfoSyncManager: IMarketInfoSyncManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartInfoManager: IChartInfoManager
    private let chartInfoSyncManager: IChartInfoSyncManager
    private let newsPostsManager: INewsManager

    init(marketInfoManager: IMarketInfoManager, topMarketsManager: ITopMarketsManager, marketInfoSyncManager: IMarketInfoSyncManager,
         historicalRateManager: IHistoricalRateManager, chartInfoManager: IChartInfoManager, chartInfoSyncManager: IChartInfoSyncManager,
         newsPostsManager: INewsManager) {
        self.topMarketsManager = topMarketsManager
        self.marketInfoManager = marketInfoManager
        self.marketInfoSyncManager = marketInfoSyncManager
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

    public func set(coinCodes: [String]) {
        marketInfoSyncManager.set(coinCodes: coinCodes)
    }

    public func set(currencyCode: String) {
        marketInfoSyncManager.set(currencyCode: currencyCode)
    }

    public func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo? {
        marketInfoManager.marketInfo(key: PairKey(coinCode: coinCode, currencyCode: currencyCode))
    }

    public func marketInfoObservable(coinCode: String, currencyCode: String) -> Observable<MarketInfo> {
        marketInfoSyncManager.marketInfoObservable(key: PairKey(coinCode: coinCode, currencyCode: currencyCode))
    }

    public func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]> {
        marketInfoSyncManager.marketInfosObservable(currencyCode: currencyCode)
    }

    public func topMarketInfos(currencyCode: String) -> Single<[TopMarket]> {
        topMarketsManager.topMarketInfos(currencyCode: currencyCode)
    }

    public func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        historicalRateManager.historicalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    public func historicalRateSingle(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        historicalRateManager.historicalRateSingle(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    public func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        chartInfoManager.chartInfo(key: ChartInfoKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType))
    }

    public func chartInfoObservable(coinCode: String, currencyCode: String, chartType:ChartType) -> Observable<ChartInfo> {
        chartInfoSyncManager.chartInfoObservable(key: ChartInfoKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType))
    }

    public func cryptoPosts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        newsPostsManager.posts(timestamp: timestamp)
    }

    public var cryptoPostsSingle: Single<[CryptoNewsPost]> {
        newsPostsManager.postsSingle(latestTimestamp: nil)
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, coinMarketCapApiKey: String? = nil, indicatorPointCount: Int = 60, marketInfoExpirationInterval: TimeInterval = 5 * 60, topMarketsCount: Int = 10, retryInterval: TimeInterval = 30, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let reachabilityManager = ReachabilityManager()

        let storage = GrdbStorage()

        let networkManager = NetworkManager(logger: logger)
        let mainProvider = CryptoCompareProvider(networkManager: networkManager, baseUrl: "https://min-api.cryptocompare.com", timeoutInterval: 10, topMarketsCount: topMarketsCount, indicatorPointCount: indicatorPointCount)
        let topMarketsProvider: ITopMarketsProvider

        if let coinMarketCapApiKey = coinMarketCapApiKey {
            topMarketsProvider = CoinMarketCapProvider(apiKey: coinMarketCapApiKey, marketInfoProvider: mainProvider, networkManager: networkManager, timeoutInterval: 10, topMarketsCount: topMarketsCount)
        } else {
            topMarketsProvider = mainProvider
        }

        let marketInfoManager = MarketInfoManager(storage: storage, expirationInterval: marketInfoExpirationInterval)
        let topMarketsManager = TopMarketsManager(storage: storage, provider: topMarketsProvider, expirationInterval: marketInfoExpirationInterval, marketsCount: topMarketsCount)
        let marketInfoSchedulerFactory = MarketInfoSchedulerFactory(manager: marketInfoManager, provider: mainProvider, reachabilityManager: reachabilityManager, expirationInterval: marketInfoExpirationInterval, retryInterval: retryInterval, logger: logger)
        let marketInfoSyncManager = MarketInfoSyncManager(currencyCode: currencyCode, schedulerFactory: marketInfoSchedulerFactory)
        marketInfoManager.delegate = marketInfoSyncManager

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: mainProvider)

        let chartInfoManager = ChartInfoManager(storage: storage, marketInfoManager: marketInfoManager)
        let chartPointSchedulerFactory = ChartPointSchedulerFactory(manager: chartInfoManager, provider: mainProvider, reachabilityManager: reachabilityManager, retryInterval: retryInterval, logger: logger)
        let chartInfoSyncManager = ChartInfoSyncManager(schedulerFactory: chartPointSchedulerFactory, chartInfoManager: chartInfoManager, marketInfoSyncManager: marketInfoSyncManager)

        chartInfoManager.delegate = chartInfoSyncManager

        let newsPostManager = NewsManager(provider: mainProvider, state: NewsState(expirationTime: 30 * 60))

        let kit = XRatesKit(
                marketInfoManager: marketInfoManager,
                topMarketsManager: topMarketsManager,
                marketInfoSyncManager: marketInfoSyncManager,
                historicalRateManager: historicalRateManager,
                chartInfoManager: chartInfoManager,
                chartInfoSyncManager: chartInfoSyncManager,
                newsPostsManager: newsPostManager
        )

        return kit
    }

}
