import RxSwift
import CoinKit

class HistoricalRateManager {
    private let storage: IHistoricalRateStorage
    private let provider: IHistoricalRateProvider

    init(storage: IHistoricalRateStorage, provider: IHistoricalRateProvider) {
        self.storage = storage
        self.provider = provider
    }

}

extension HistoricalRateManager: IHistoricalRateManager {

    func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal? {
        storage.rate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)?.value
    }

    func historicalRateSingle(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal> {
        if let dbRate = storage.rate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp) {
            return Single.just(dbRate.value)
        }

        return provider.getHistoricalRate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
                .do(onSuccess: { [weak self] rateValue in
                    let rate = HistoricalRate(coinType: coinType, currencyCode: currencyCode, value: rateValue, timestamp: timestamp)
                    self?.storage.save(historicalRate: rate)
                })
    }

}
