import RxSwift

public class XRatesKit {
    private let latestRateManager: ILatestRateManager
    private let latestRateSyncManager: ILatestRateSyncManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartInfoManager: IChartInfoManager
    private let chartInfoSyncManager: IChartInfoSyncManager
    private let marketInfoManager: IMarketInfoManager

    init(latestRateManager: ILatestRateManager, latestRateSyncManager: ILatestRateSyncManager, historicalRateManager: IHistoricalRateManager, chartInfoManager: IChartInfoManager, chartInfoSyncManager: IChartInfoSyncManager, marketInfoManager: IMarketInfoManager) {
        self.latestRateManager = latestRateManager
        self.latestRateSyncManager = latestRateSyncManager
        self.chartInfoManager = chartInfoManager
        self.chartInfoSyncManager = chartInfoSyncManager
        self.historicalRateManager = historicalRateManager
        self.marketInfoManager = marketInfoManager
    }

}

extension XRatesKit {

    public func refresh() {
        latestRateSyncManager.refresh()
    }

    public func set(coinCodes: [String]) {
        latestRateSyncManager.set(coinCodes: coinCodes)
    }

    public func set(currencyCode: String) {
        latestRateSyncManager.set(currencyCode: currencyCode)
    }

    public func latestRate(coinCode: String, currencyCode: String) -> Rate? {
        latestRateManager.latestRate(key: RateKey(coinCode: coinCode, currencyCode: currencyCode))
    }

    public func latestRateObservable(coinCode: String, currencyCode: String) -> Observable<Rate> {
        latestRateSyncManager.latestRateObservable(key: RateKey(coinCode: coinCode, currencyCode: currencyCode))
    }

    public func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        historicalRateManager.historicalRateSingle(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
    }

    public func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        chartInfoManager.chartInfo(key: ChartInfoKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType))
    }

    public func chartInfoObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo> {
        chartInfoSyncManager.chartInfoObservable(key: ChartInfoKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType))
    }

    public func marketInfo(coinCode: String, currencyCode: String) -> Single<MarketInfo> {
        marketInfoManager.marketInfoSingle(coinCode: coinCode, currencyCode: currencyCode)
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, latestRateExpirationInterval: TimeInterval = 5 * 60, retryInterval: TimeInterval = 10, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let reachabilityManager = ReachabilityManager()

        let storage = GrdbStorage()

        let networkManager = NetworkManager(logger: logger)
        let cryptoCompareFactory = CryptoCompareFactory()
        let cryptoCompareProvider = CryptoCompareProvider(networkManager: networkManager, cryptoCompareFactory: cryptoCompareFactory, baseUrl: "https://min-api.cryptocompare.com", timeoutInterval: 10)

        let latestRateManager = LatestRateManager(storage: storage, expirationInterval: latestRateExpirationInterval)
        let latestRateSchedulerFactory = LatestRateSchedulerFactory(manager: latestRateManager, provider: cryptoCompareProvider, reachabilityManager: reachabilityManager, expirationInterval: latestRateExpirationInterval, retryInterval: retryInterval, logger: logger)
        let latestRateSyncManager = LatestRateSyncManager(currencyCode: currencyCode, schedulerFactory: latestRateSchedulerFactory)

        latestRateManager.delegate = latestRateSyncManager

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: cryptoCompareProvider)

        let chartInfoManager = ChartInfoManager(storage: storage, latestRateManager: latestRateManager)
        let chartPointSchedulerFactory = ChartPointSchedulerFactory(manager: chartInfoManager, provider: cryptoCompareProvider, reachabilityManager: reachabilityManager, retryInterval: retryInterval, logger: logger)
        let chartInfoSyncManager = ChartInfoSyncManager(schedulerFactory: chartPointSchedulerFactory, chartInfoManager: chartInfoManager, latestRateSyncManager: latestRateSyncManager)

        chartInfoManager.delegate = chartInfoSyncManager

        let marketInfoManager = MarketInfoManager(storage: storage, provider: cryptoCompareProvider)

        let kit = XRatesKit(
                latestRateManager: latestRateManager,
                latestRateSyncManager: latestRateSyncManager,
                historicalRateManager: historicalRateManager,
                chartInfoManager: chartInfoManager,
                chartInfoSyncManager: chartInfoSyncManager,
                marketInfoManager: marketInfoManager
        )

        return kit
    }

}
