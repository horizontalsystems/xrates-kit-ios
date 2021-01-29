import RxSwift

class CoinGeckoManager {
    private let disposeBag = DisposeBag()

    private let provider: CoinGeckoProvider
    private let storage: IProviderCoinInfoStorage

    init(provider: CoinGeckoProvider, storage: IProviderCoinInfoStorage) {
        self.provider = provider
        self.storage = storage
    }

    private func coinIds(coinCodes: [String]) -> Single<String> {
        let coinInfosSingle: Single<[ProviderCoinInfoRecord]>

        if storage.providerCoinInfoCount != 0 {
            let providerCoinInfos = storage.providerCoinInfos(coinCodes: coinCodes)
            coinInfosSingle = Single.just(providerCoinInfos)
        } else {
            coinInfosSingle = provider.coinInfosSingle().map { [weak self] coinInfos in
                self?.storage.save(providerCoinInfos: coinInfos)
                return coinInfos.filter { coinInfo in coinCodes.contains { coinInfo.code == $0 } }
            }
        }

        return coinInfosSingle.map { providerCoinInfos in
            guard !providerCoinInfos.isEmpty else {
                return ""
            }

            let coinIds = providerCoinInfos.map { $0.coinId }
            return "&ids=\(coinIds.joined(separator: ","))"
        }
    }

}

extension CoinGeckoManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        provider.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinCodes: [String]) -> Single<[CoinMarket]> {
        coinIds(coinCodes: coinCodes).flatMap { [weak self] coinIds in
            guard let provider = self?.provider, !coinIds.isEmpty else {
                return Single.just([])
            }
            return provider.coinMarketsSingle(
                    currencyCode: currencyCode,
                    fetchDiffPeriod: fetchDiffPeriod,
                    coinIds: coinIds)
        }
    }

}
