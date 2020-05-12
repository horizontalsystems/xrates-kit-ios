import RxSwift

class MarketInfoSchedulerProvider {
    private var coinCodes: [String]
    private let currencyCode: String
    private let manager: IMarketInfoManager
    private let provider: IMarketInfoProvider

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(coinCodes: [String], currencyCode: String, manager: IMarketInfoManager, provider: IMarketInfoProvider, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.coinCodes = coinCodes
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private func handle(updatedRecords: [MarketInfoRecord]) {
        coinCodes.removeAll { coinCode in
            !updatedRecords.contains { record in
                record.key.coinCode == coinCode
            }
        }

        manager.handleUpdated(records: updatedRecords, currencyCode: currencyCode)
    }

}

extension MarketInfoSchedulerProvider: IMarketInfoSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(coinCodes: coinCodes, currencyCode: currencyCode)
    }

    var syncSingle: Single<Void> {
        provider.getMarketInfoRecords(coinCodes: coinCodes, currencyCode: currencyCode)
                .do(onSuccess: { [weak self] records in
                    self?.handle(updatedRecords: records)
                })
                .map { _ in () }
    }

    func notifyExpired() {
        manager.notifyExpired(coinCodes: coinCodes, currencyCode: currencyCode)
    }

}
