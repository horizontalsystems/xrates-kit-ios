import RxSwift

class CoinGeckoManager {
    enum CoinIdError: Error {
        case noMatchingCoinId
    }

    private let disposeBag = DisposeBag()

    private let provider: CoinGeckoProvider
    private let storage: IProviderCoinInfoStorage & IMarketInfoStorage
    private let externalIdManager: ProviderCoinsManager

    init(provider: CoinGeckoProvider, storage: IProviderCoinInfoStorage & IMarketInfoStorage, externalIdManager: ProviderCoinsManager) {
        self.provider = provider
        self.storage = storage
        self.externalIdManager = externalIdManager
    }

}

extension CoinGeckoManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        provider
            .topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
            .do { [weak self] coinMarkets in
                let marketInfoRecords = coinMarkets.map {
                    MarketInfoRecord(marketInfo: $0.marketInfo, coin: $0.coin)
                }

                self?.storage.save(marketInfoRecords: marketInfoRecords)
            }
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinIds: [String]) -> Single<[CoinMarket]> {
        let externalIds = coinIds.compactMap { externalIdManager.providerId(id: $0, providerName: CoinGeckoProvider.providerName) }

        return provider.coinMarketsSingle(
                    currencyCode: currencyCode,
                    fetchDiffPeriod: fetchDiffPeriod,
                    coinIds: "&ids=\(externalIds.joined(separator: ","))"
        )
    }

    func coinMarketInfoSingle(coinId: String, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        guard let externalId = externalIdManager.providerId(id: coinId, providerName: CoinGeckoProvider.providerName) else {
            return Single.error(CoinIdError.noMatchingCoinId)
        }

        return provider.coinMarketInfoSingle(coinCode: externalId, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
    }

}
