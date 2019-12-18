import RxSwift

class HistoricalRateManager {
    private let storage: IHistoricalRateStorage
    private let provider: IHistoricalRateProvider

    init(storage: IHistoricalRateStorage, provider: IHistoricalRateProvider) {
        self.storage = storage
        self.provider = provider
    }

}

extension HistoricalRateManager: IHistoricalRateManager {

    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        storage.rate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)?.value
    }

    func historicalRateSingle(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        if let dbRate = storage.rate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp) {
            return Single.just(dbRate.value)
        }

        return provider.getHistoricalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                .do(onSuccess: { [weak self] rateValue in
                    let rate = HistoricalRate(coinCode: coinCode, currencyCode: currencyCode, value: rateValue, timestamp: timestamp)
                    self?.storage.save(historicalRate: rate)
                })
    }

}
