import RxSwift

class TopMarketsSyncer {
    private let currencyCode: String
    private let manager: ITopMarketsManager
    private let provider: IMarketInfoProvider

    init(currencyCode: String, provider: IMarketInfoProvider, manager: ITopMarketsManager) {
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
    }

    private func handle(updatedRecords: [MarketInfoRecord]) {
        manager.handleUpdated(records: updatedRecords)
    }

}

extension TopMarketsSyncer: IMarketInfoSyncer {

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

