import RxSwift

public class XRatesKit {
    private let marketInfoManager: IMarketInfoManager
    private let marketInfoSyncManager: IMarketInfoSyncManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartInfoManager: IChartInfoManager
    private let chartInfoSyncManager: IChartInfoSyncManager
    private let newsPostsManager: INewsManager

    init(marketInfoManager: IMarketInfoManager, marketInfoSyncManager: IMarketInfoSyncManager, historicalRateManager: IHistoricalRateManager, chartInfoManager: IChartInfoManager, chartInfoSyncManager: IChartInfoSyncManager, newsPostsManager: INewsManager) {
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

    public func cryptoPosts(for coinName: String, timestamp: TimeInterval) -> [CryptoNewsPost]? {
        newsPostsManager.posts(for: coinName, timestamp: timestamp)
    }

    public func cryptoPostsSingle(for coinName: String) -> Single<[CryptoNewsPost]> {
        newsPostsManager.postsSingle(for: coinName, latestTimestamp: nil)
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, marketInfoExpirationInterval: TimeInterval = 5 * 60, retryInterval: TimeInterval = 30, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let reachabilityManager = ReachabilityManager()

        let storage = GrdbStorage()

        let networkManager = NetworkManager(logger: logger)
        let cryptoCompareProvider = CryptoCompareProvider(networkManager: networkManager, baseUrl: "https://min-api.cryptocompare.com", timeoutInterval: 10)

        let marketInfoManager = MarketInfoManager(storage: storage, expirationInterval: marketInfoExpirationInterval)
        let marketInfoSchedulerFactory = MarketInfoSchedulerFactory(manager: marketInfoManager, provider: cryptoCompareProvider, reachabilityManager: reachabilityManager, expirationInterval: marketInfoExpirationInterval, retryInterval: retryInterval, logger: logger)
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
                marketInfoSyncManager: marketInfoSyncManager,
                historicalRateManager: historicalRateManager,
                chartInfoManager: chartInfoManager,
                chartInfoSyncManager: chartInfoSyncManager,
                newsPostsManager: newsPostManager
        )

        return kit
    }

}
