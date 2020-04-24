import Foundation

class TopMarketsSchedulerFactory {
    private let manager: ITopMarketsManager
    private let provider: ITopMarketsProvider
    private let reachabilityManager: IReachabilityManager
    private let expirationInterval: TimeInterval
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(manager: ITopMarketsManager, provider: ITopMarketsProvider, reachabilityManager: IReachabilityManager, expirationInterval: TimeInterval, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.manager = manager
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(currencyCode: String) -> MarketInfoScheduler {
        let schedulerProvider = TopMarketsSchedulerProvider(
                currencyCode: currencyCode,
                manager: manager,
                provider: provider,
                expirationInterval: expirationInterval,
                retryInterval: retryInterval
        )

        return MarketInfoScheduler(name: "TOP MARKETS", provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
