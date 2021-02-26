import RxSwift
import CoinKit

class MarketInfoSchedulerProvider {
    private var coinTypes: [CoinType]

    private let currencyCode: String
    private let manager: IMarketInfoManager
    private let provider: IMarketInfoProvider

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(coinTypes: [CoinType], currencyCode: String, manager: IMarketInfoManager, provider: IMarketInfoProvider, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.coinTypes = coinTypes
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private func handle(updatedRecords: [MarketInfoRecord]) {
        coinTypes.removeAll { coinType in
            !updatedRecords.contains { record in
                record.key.coinType == coinType
            }
        }

        manager.handleUpdated(records: updatedRecords, currencyCode: currencyCode)
    }

}

extension MarketInfoSchedulerProvider: IMarketInfoSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(coinTypes: coinTypes, currencyCode: currencyCode)
    }

    var syncSingle: Single<Void> {
        provider.marketInfoRecords(coinTypes: coinTypes, currencyCode: currencyCode)
                .do(onSuccess: { [weak self] records in
                    self?.handle(updatedRecords: records)
                })
                .map { _ in () }
    }

    func notifyExpired() {
        manager.notifyExpired(coinTypes: coinTypes, currencyCode: currencyCode)
    }

}
