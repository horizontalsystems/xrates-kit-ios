import RxSwift
private struct CoinGeckoDuplicateMap {

    static let coinIds = [
        "bowl-a-coin", "blockidcoin", "bifi",
        "bitcoin-file", "cactus-finance","coin-artist",
        "stake-coin-2", "derogold", "daily-funds",
        "deipool", "dipper", "dipper-network", "demos",
        "defi-nation-signals-dao", "digitalusd", "seed2need",
        "fin-token", "funkeypay", "freetip",
        "golden-ratio-token", "gdac-token", "bonded-finance",
        "compound-coin", "hydro-protocol", "thorchain",
        "holy-trinity", "wrapped-terra", "memetic",
        "mir-coin", "morpher", "master-usd", "payperex",
        "baby-power-index-pool-token", "san-diego-coin",
        "siambitcoin", "soft-bitcoin", "stakehound-staked-ether",
        "super-bitcoin", "socketfinance", "unicorn-token",
        "universe-token", "dollars", "usdx-stablecoin", "usdx-wallet"
    ]

}

class CoinGeckoManager {
    private let disposeBag = DisposeBag()

    private let provider: CoinGeckoProvider
    private let storage: IProviderCoinInfoStorage & IMarketInfoStorage

    init(provider: CoinGeckoProvider, storage: IProviderCoinInfoStorage & IMarketInfoStorage) {
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
                let reducedCoinInfos = self?.removeDuplicate(coinInfos: coinInfos) ?? []

                self?.storage.save(providerCoinInfos: reducedCoinInfos)
                return reducedCoinInfos.filter { coinInfo in coinCodes.contains { coinInfo.code == $0 } }
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

    private func removeDuplicate(coinInfos: [ProviderCoinInfoRecord]) -> [ProviderCoinInfoRecord] {
        coinInfos.filter { record in !CoinGeckoDuplicateMap.coinIds.contains(record.coinId) }
    }

}

extension CoinGeckoManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        provider
            .topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
            .do { [weak self] coinMarkets in
                let reducedCoinMarkets = coinMarkets.filter { coinMarket in
                    !CoinGeckoDuplicateMap.coinIds.contains(coinMarket.marketInfo.coinId)
                }

                let marketInfoRecords = reducedCoinMarkets.map {
                    MarketInfoRecord(marketInfo: $0.marketInfo, coin: $0.coin)
                }

                self?.storage.save(marketInfoRecords: marketInfoRecords)
            }
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
