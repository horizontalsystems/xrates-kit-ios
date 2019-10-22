import RxSwift

class LatestRateSchedulerProvider {
    private let coinCodes: [String]
    private let currencyCode: String
    private let manager: ILatestRateManager
    private let provider: ILatestRateProvider

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(coinCodes: [String], currencyCode: String, manager: ILatestRateManager, provider: ILatestRateProvider, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.coinCodes = coinCodes
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private func handle(rateResponses: [RateResponse]) {
        let rates = coinCodes.map { coinCode -> LatestRate in
            let value = rateResponses.first(where: { $0.coinCode == coinCode })?.value ?? 0
            return LatestRate(coinCode: coinCode, currencyCode: currencyCode, value: value, timestamp: Date().timeIntervalSince1970)
        }

        manager.handleUpdated(rates: rates)
    }

}

extension LatestRateSchedulerProvider: ILatestRateSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(coinCodes: coinCodes, currencyCode: currencyCode)
    }

    var syncSingle: Single<Void> {
        provider.getLatestRates(coinCodes: coinCodes, currencyCode: currencyCode)
                .do(onSuccess: { [weak self] rateResponses in
                    self?.handle(rateResponses: rateResponses)
                })
                .map { _ in () }
    }

    func notifyExpiredRates() {
        manager.notifyExpiredRates(coinCodes: coinCodes, currencyCode: currencyCode)
    }

}
