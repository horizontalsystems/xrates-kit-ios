import RxSwift
import CoinKit

class LatestRatesSchedulerProvider {
    private var coinTypes: [CoinType]

    private let currencyCode: String
    private let manager: ILatestRatesManager
    private let provider: ILatestRatesProvider

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(coinTypes: [CoinType], currencyCode: String, manager: ILatestRatesManager, provider: ILatestRatesProvider, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.coinTypes = coinTypes
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private func handle(updatedRecords: [LatestRateRecord]) {
        coinTypes.removeAll { coinType in
            !updatedRecords.contains { record in
                record.key.coinType == coinType
            }
        }

        manager.handleUpdated(records: updatedRecords, currencyCode: currencyCode)
    }

}

extension LatestRatesSchedulerProvider: IMarketInfoSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(coinTypes: coinTypes, currencyCode: currencyCode)
    }

    var syncSingle: Single<Void> {
        provider.latestRateRecords(coinTypes: coinTypes, currencyCode: currencyCode)
                .do(onSuccess: { [weak self] records in
                    self?.handle(updatedRecords: records)
                })
                .map { _ in () }
    }

    func notifyExpired() {
        manager.notifyExpired(coinTypes: coinTypes, currencyCode: currencyCode)
    }

}
