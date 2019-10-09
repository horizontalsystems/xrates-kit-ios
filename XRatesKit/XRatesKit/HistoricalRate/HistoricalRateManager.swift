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

    func getHistoricalRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        if let dbRate = storage.rate(coinCode: coinCode, currencyCode: currencyCode, date: date) {
            return Single.just(dbRate.value)
        }
        return provider.getHistoricalRate(coinCode: coinCode, currencyCode: currencyCode, date: date)
                .do(onSuccess: { [weak self] rate in
                    self?.storage.save(rate: rate)
                }).map { rate -> Decimal in
                    rate.value
                }
    }

}