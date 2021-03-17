import Foundation
import HsToolKit
import CoinKit

class LatestRatesSchedulerFactory {
    private let manager: ILatestRatesManager
    private let provider: ILatestRatesProvider
    private let reachabilityManager: IReachabilityManager
    private let expirationInterval: TimeInterval
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(manager: ILatestRatesManager, provider: ILatestRatesProvider, reachabilityManager: IReachabilityManager, expirationInterval: TimeInterval, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.manager = manager
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(coinTypes: [CoinType], currencyCode: String) -> LatestRatesScheduler {
        let schedulerProvider = LatestRatesSchedulerProvider(
                coinTypes: coinTypes,
                currencyCode: currencyCode,
                manager: manager,
                provider: provider,
                expirationInterval: expirationInterval,
                retryInterval: retryInterval
        )

        return LatestRatesScheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
