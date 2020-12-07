import RxSwift

class MarketInfoSchedulerProvider {
    private var coins: [XRatesKit.Coin]

    private let currencyCode: String
    private let manager: IMarketInfoManager
    private let provider: IMarketInfoProvider

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(coins: [XRatesKit.Coin], currencyCode: String, manager: IMarketInfoManager, provider: IMarketInfoProvider, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.coins = coins
        self.currencyCode = currencyCode
        self.manager = manager
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

    private func handle(updatedRecords: [MarketInfoRecord]) {
        var records = updatedRecords.compactMap { record -> MarketInfoRecord? in
            if let matchedCoin = coins.first { $0.code.uppercased() == record.coinCode.uppercased() } {
                record.coinCode = matchedCoin.code
                return record
            }

            return nil
        }

        coins.removeAll { coin in
            !records.contains { record in
                record.key.coinCode == coin.code
            }
        }

        manager.handleUpdated(records: records, currencyCode: currencyCode)
    }

}

extension MarketInfoSchedulerProvider: IMarketInfoSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        manager.lastSyncTimestamp(coinCodes: coins.map { $0.code }, currencyCode: currencyCode)
    }

    var syncSingle: Single<Void> {
        provider.getMarketInfoRecords(coins: coins, currencyCode: currencyCode)
                .do(onSuccess: { [weak self] records in
                    self?.handle(updatedRecords: records)
                })
                .map { _ in () }
    }

    func notifyExpired() {
        manager.notifyExpired(coinCodes: coins.map { $0.code }, currencyCode: currencyCode)
    }

}
