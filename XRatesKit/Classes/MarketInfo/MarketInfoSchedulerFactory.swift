import Foundation

class MarketInfoSchedulerFactory {
    private let marketInfoManager: IMarketInfoManager
    private let topMarketsManager: ITopMarketsManager
    private let provider: IMarketInfoProvider
    private let storage: IMarketInfoStorage
    private let reachabilityManager: IReachabilityManager
    private let expirationInterval: TimeInterval
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(marketsInfoManager: IMarketInfoManager, topMarketsManager: ITopMarketsManager, provider: IMarketInfoProvider, storage: IMarketInfoStorage, reachabilityManager: IReachabilityManager, expirationInterval: TimeInterval, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.marketInfoManager = marketsInfoManager
        self.topMarketsManager = topMarketsManager
        self.provider = provider
        self.storage = storage
        self.reachabilityManager = reachabilityManager
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(coinCodes: [String], currencyCode: String) -> MarketInfoScheduler {
        let schedulerProvider = MarketInfoSchedulerProvider(
                coinCodes: coinCodes,
                currencyCode: currencyCode,
                storage: storage,
                expirationInterval: expirationInterval,
                retryInterval: retryInterval
        )

        return MarketInfoScheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

    func marketInfoSyncer(coinCodes: [String], currencyCode: String) -> IMarketInfoSyncer {
        MarketInfoSyncer(coinCodes: coinCodes, currencyCode: currencyCode, provider: provider, manager: marketInfoManager)
    }

    func topMarketsSyncer(currencyCode: String) -> IMarketInfoSyncer {
        TopMarketsSyncer(currencyCode: currencyCode, provider: provider, manager: topMarketsManager)
    }
}
