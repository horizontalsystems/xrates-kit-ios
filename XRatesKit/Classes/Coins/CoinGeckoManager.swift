import RxSwift
import CoinKit

class CoinGeckoManager {
    private let disposeBag = DisposeBag()

    private let provider: CoinGeckoProvider
    private let storage: IProviderCoinInfoStorage & IMarketInfoStorage

    init(provider: CoinGeckoProvider, storage: IProviderCoinInfoStorage & IMarketInfoStorage) {
        self.provider = provider
        self.storage = storage
    }

}

extension CoinGeckoManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        provider
            .topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
            .do { [weak self] coinMarkets in
                let marketInfoRecords = coinMarkets.map {
                    MarketInfoRecord(marketInfo: $0.marketInfo, coinType: $0.coinType, coinCode: $0.coinCode)
                }

                self?.storage.save(marketInfoRecords: marketInfoRecords)
            }
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinTypes: [CoinType]) -> Single<[CoinMarket]> {
        provider.coinMarketsSingle(
                    currencyCode: currencyCode,
                    fetchDiffPeriod: fetchDiffPeriod,
                    coinTypes: coinTypes
        )
    }

    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        provider.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
    }

}
