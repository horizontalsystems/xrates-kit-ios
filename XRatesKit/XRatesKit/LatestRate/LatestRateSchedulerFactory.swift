import Foundation

class LatestRateSchedulerFactory {
    private let manager: ILatestRateManager
    private let provider: ILatestRateProvider
    private let reachabilityManager: IReachabilityManager
    private let expirationInterval: TimeInterval
    private let retryInterval: TimeInterval
    private var logger: Logger?

    init(manager: ILatestRateManager, provider: ILatestRateProvider, reachabilityManager: IReachabilityManager, expirationInterval: TimeInterval, retryInterval: TimeInterval, logger: Logger? = nil) {
        self.manager = manager
        self.provider = provider
        self.reachabilityManager = reachabilityManager
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
        self.logger = logger
    }

    func scheduler(coinCodes: [String], currencyCode: String) -> LatestRateScheduler {
        let schedulerProvider = LatestRateSchedulerProvider(
                coinCodes: coinCodes,
                currencyCode: currencyCode,
                manager: manager,
                provider: provider,
                expirationInterval: expirationInterval,
                retryInterval: retryInterval
        )

        return LatestRateScheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
