import Foundation
import HsToolKit

class MarketInfoSchedulerFactory {
    private let manager: IMarketInfoManager
    private let provider: IMarketInfoProvider
    private let reachabilityManager: IReachabilityManager
    private let expirationInterval: TimeInterval
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(manager: IMarketInfoManager, provider: IMarketInfoProvider, reachabilityManager: IReachabilityManager, expirationInterval: TimeInterval, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.manager = manager
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(coinCodes: [String], currencyCode: String) -> MarketInfoScheduler {
        let schedulerProvider = MarketInfoSchedulerProvider(
                coinCodes: coinCodes,
                currencyCode: currencyCode,
                manager: manager,
                provider: provider,
                expirationInterval: expirationInterval,
                retryInterval: retryInterval
        )

        return MarketInfoScheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
