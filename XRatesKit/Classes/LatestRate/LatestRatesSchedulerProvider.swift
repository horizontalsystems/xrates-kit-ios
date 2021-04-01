import RxSwift
import CoinKit

class LatestRatesSchedulerProvider {
    private let currencyCode: String

    private let manager: ILatestRatesManager
    private let provider: ILatestRatesProvider

    weak var dataSource: ILatestRatesCoinTypeDataSource?

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(manager: ILatestRatesManager, provider: ILatestRatesProvider, currencyCode: String, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.manager = manager
        self.provider = provider
        self.currencyCode = currencyCode
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private var coinTypes: [CoinType] {
        dataSource?.coinTypes(currencyCode: currencyCode) ?? []
    }

    private func handle(updatedRecords: [LatestRateRecord]) {
        manager.handleUpdated(records: updatedRecords, currencyCode: currencyCode)
    }

}

extension LatestRatesSchedulerProvider: ISchedulerProvider {

    var id: String {
        "LatestRateProvider"
    }

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
