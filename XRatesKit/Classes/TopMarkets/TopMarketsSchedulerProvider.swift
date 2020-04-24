import RxSwift

class TopMarketsSchedulerProvider {
    private let currencyCode: String
    private let manager: ITopMarketsManager
    private let provider: ITopMarketsProvider

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(currencyCode: String, manager: ITopMarketsManager, provider: ITopMarketsProvider, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private func handle(updatedRecords: [TopMarketInfoRecord]) {
        manager.handleUpdated(records: updatedRecords)
    }

}

extension TopMarketsSchedulerProvider: IMarketInfoSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(currencyCode: currencyCode)
    }

    var syncSingle: Single<Void> {
        provider.getTopMarketInfoRecords(currencyCode: currencyCode)
                .do(onSuccess: { [weak self] records in
                    self?.handle(updatedRecords: records)
                })
                .map { _ in () }
    }

    func notifyExpired() {
        manager.notifyExpired(currencyCode: currencyCode)
    }

}
