import RxSwift
import HsToolKit

public class XRatesKit {
    private let marketInfoManager: IMarketInfoManager
    private let topMarketsManager: ITopMarketsManager
    private let globalMarketInfoManager: GlobalMarketInfoManager
    private let marketInfoSyncManager: IMarketInfoSyncManager
    private let historicalRateManager: IHistoricalRateManager
    private let chartInfoManager: IChartInfoManager
    private let chartInfoSyncManager: IChartInfoSyncManager
    private let newsPostsManager: INewsManager

    init(marketInfoManager: IMarketInfoManager, topMarketsManager: ITopMarketsManager, globalMarketInfoManager: GlobalMarketInfoManager,
         marketInfoSyncManager: IMarketInfoSyncManager, historicalRateManager: IHistoricalRateManager, chartInfoManager: IChartInfoManager,
         chartInfoSyncManager: IChartInfoSyncManager, newsPostsManager: INewsManager) {
        self.topMarketsManager = topMarketsManager
        self.globalMarketInfoManager = globalMarketInfoManager
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

    public func set(coins: [Coin]) {
        marketInfoSyncManager.set(coins: coins)
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

    public func cryptoPosts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        newsPostsManager.posts(timestamp: timestamp)
    }

    public var cryptoPostsSingle: Single<[CryptoNewsPost]> {
        newsPostsManager.postsSingle(latestTimestamp: nil)
    }

    public func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, itemsCount: Int = 200) -> Single<[TopMarket]> {
        topMarketsManager.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemsCount: itemsCount)
    }

    public func topDefiMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod = .hour24, itemsCount: Int = 200) -> Single<[TopMarket]> {
        topMarketsManager.topDefiMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemsCount: itemsCount)
    }

    public func globalMarketInfoSingle(currencyCode: String) -> Single<GlobalMarketInfo> {
        globalMarketInfoManager.globalMarketInfo(currencyCode: currencyCode)
    }


}

extension XRatesKit {

    public static func instance(currencyCode: String, coinMarketCapApiKey: String? = nil, cryptoCompareApiKey: String? = nil, uniswapSubgraphUrl: String, indicatorPointCount: Int = 60, marketInfoExpirationInterval: TimeInterval = 60, topMarketsCount: Int = 10, retryInterval: TimeInterval = 30, minLogLevel: Logger.Level = .error) -> XRatesKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let reachabilityManager = ReachabilityManager()

        let storage = GrdbStorage()

        let networkManager = NetworkManager(logger: logger)
        let cryptoCompareProvider = CryptoCompareProvider(networkManager: networkManager, baseUrl: "https://min-api.cryptocompare.com", apiKey: cryptoCompareApiKey, timeoutInterval: 10, expirationInterval: marketInfoExpirationInterval, topMarketsCount: topMarketsCount, indicatorPointCount: indicatorPointCount)
        let uniswapSubgraphProvider = UniswapSubgraphProvider(fiatXRatesProvider: cryptoCompareProvider, networkManager: networkManager, baseUrl: uniswapSubgraphUrl, expirationInterval: marketInfoExpirationInterval)
        let baseMarketInfoProvider = BaseMarketInfoProvider(mainProvider: cryptoCompareProvider, uniswapGraphProvider: uniswapSubgraphProvider)
        let globalMarketInfoProvider = CoinPaprikaProvider(networkManager: networkManager)
        let topMarketsProvider = CoinGeckoProvider(networkManager: networkManager, expirationInterval: marketInfoExpirationInterval)

        let marketInfoManager = MarketInfoManager(storage: storage, expirationInterval: marketInfoExpirationInterval)
        let topMarketsManager = TopMarketsManager(storage: storage, topProvider: topMarketsProvider, topDefiProvider: uniswapSubgraphProvider, expirationInterval: marketInfoExpirationInterval, marketsCount: topMarketsCount)
        let globalMarketInfoManager = GlobalMarketInfoManager(globalMarketInfoProvider: globalMarketInfoProvider, storage: storage)
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
                topMarketsManager: topMarketsManager,
                globalMarketInfoManager: globalMarketInfoManager,
                marketInfoSyncManager: marketInfoSyncManager,
                historicalRateManager: historicalRateManager,
                chartInfoManager: chartInfoManager,
                chartInfoSyncManager: chartInfoSyncManager,
                newsPostsManager: newsPostManager
        )

        return kit
    }

}

extension XRatesKit {

    public struct Coin {
        public let code: String
        public let title: String
        public let type: CoinType?

        public init(code: String, title: String, type: CoinType? = nil) {
            self.code = code
            self.title = title
            self.type = type
        }

    }

    public enum CoinType {
        case bitcoin
        case litecoin
        case bitcoinCash
        case dash
        case ethereum
        case erc20(address: String)
        case binance
        case zcash
        case eos
    }

}
