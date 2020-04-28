import RxSwift

class MarketInfoSyncer {
    private var coinCodes: [String]
    private let currencyCode: String
    private let provider: IMarketInfoProvider
    private let manager: IMarketInfoManager

    init(coinCodes: [String], currencyCode: String, provider: IMarketInfoProvider, manager: IMarketInfoManager) {
        self.coinCodes = coinCodes
        self.currencyCode = currencyCode
        self.provider = provider
        self.manager = manager
    }

    private func handle(updatedRecords: [MarketInfoRecord]) {
        coinCodes.removeAll { coinCode in
            !updatedRecords.contains { record in
                record.coinCode == coinCode
            }
        }

        manager.handleUpdated(records: updatedRecords, currencyCode: currencyCode)
    }

}

extension MarketInfoSyncer: IMarketInfoSyncer {

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