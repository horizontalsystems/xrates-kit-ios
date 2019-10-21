import RxSwift

public class XRatesKit {
    private let latestRateManager: ILatestRateManager
    private let latestRateSyncManager: ILatestRateSyncManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartPointManager: IChartPointManager
    private let chartPointSyncManager: IChartPointSyncManager

    init(latestRateManager: ILatestRateManager, latestRateSyncManager: ILatestRateSyncManager, historicalRateManager: IHistoricalRateManager, chartPointManager: IChartPointManager, chartPointSyncManager: IChartPointSyncManager) {
        self.latestRateManager = latestRateManager
        self.latestRateSyncManager = latestRateSyncManager
        self.chartPointManager = chartPointManager
        self.chartPointSyncManager = chartPointSyncManager
        self.historicalRateManager = historicalRateManager
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

    public func historicalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        historicalRateManager.historicalRateSingle(coinCode: coinCode, currencyCode: currencyCode, date: date)
    }

    public func chartPoints(coinCode: String, currencyCode: String, chartType: ChartType) -> [ChartPoint] {
        chartPointManager.chartPoints(key: ChartPointKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType))
    }

    public func chartPointsObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<[ChartPoint]> {
        chartPointSyncManager.chartPointsObservable(key: ChartPointKey(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType))
    }

}

extension XRatesKit {

    public static func instance(currencyCode: String, latestRateExpirationInterval: TimeInterval = 5 * 60, retryInterval: TimeInterval = 10, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)
        let currentDateProvider = CurrentDateProvider()

        let reachabilityManager = ReachabilityManager()

        let storage = GrdbStorage()

        let networkManager = NetworkManager(logger: logger)
        let cryptoCompareFactory = CryptoCompareFactory(dateProvider: currentDateProvider)
        let cryptoCompareProvider = CryptoCompareProvider(networkManager: networkManager, cryptoCompareFactory: cryptoCompareFactory, baseUrl: "https://min-api.cryptocompare.com", timeoutInterval: 10)

        let latestRateManager = LatestRateManager(storage: storage, expirationInterval: latestRateExpirationInterval)
        let latestRateSchedulerFactory = LatestRateSchedulerFactory(manager: latestRateManager, provider: cryptoCompareProvider, reachabilityManager: reachabilityManager, expirationInterval: latestRateExpirationInterval, retryInterval: retryInterval, logger: logger)
        let latestRateSyncManager = LatestRateSyncManager(currencyCode: currencyCode, schedulerFactory: latestRateSchedulerFactory)

        latestRateManager.delegate = latestRateSyncManager

        let historicalRateManager = HistoricalRateManager(storage: storage, provider: cryptoCompareProvider)

        let chartPointManager = ChartPointManager(storage: storage, latestRateManager: latestRateManager)
        let chartPointSchedulerFactory = ChartPointSchedulerFactory(manager: chartPointManager, provider: cryptoCompareProvider, reachabilityManager: reachabilityManager, retryInterval: retryInterval, logger: logger)
        let chartPointSyncManager = ChartPointSyncManager(schedulerFactory: chartPointSchedulerFactory, chartPointManager: chartPointManager, latestRateSyncManager: latestRateSyncManager)

        chartPointManager.delegate = chartPointSyncManager

        let kit = XRatesKit(latestRateManager: latestRateManager, latestRateSyncManager: latestRateSyncManager, historicalRateManager: historicalRateManager, chartPointManager: chartPointManager, chartPointSyncManager: chartPointSyncManager)

        return kit
    }

}
