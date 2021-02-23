import RxSwift
private struct CoinGeckoDuplicateMap {

    static let coinIds = [
        "ankreth", "baby-power-index-pool-token", "bifi", "bitcoin-file", "blockidcoin",
        "bonded-finance", "bowl-a-coin", "btc-alpha-token", "cactus-finance", "coin-artist",
        "compound-coin", "daily-funds", "defi-bids", "defi-nation-signals-dao", "deipool",
        "demos", "derogold", "digitalusd", "dipper", "dipper-network", "dollars",
        "fin-token", "freetip", "funkeypay", "gdac-token", "golden-ratio-token",
        "holy-trinity", "hotnow", "hydro-protocol", "lition", "master-usd",
        "memetic", "mir-coin", "morpher", "name-changing-token", "payperex",
        "radium", "san-diego-coin", "seed2need", "shardus", "siambitcoin",
        "socketfinance", "soft-bitcoin", "spacechain", "stake-coin-2", "stakehound-staked-ether",
        "super-bitcoin", "thorchain-erc20", "unicorn-token", "unit-protocol-duck", "universe-token",
        "usdx-stablecoin", "usdx-wallet", "wrapped-terra", "yield",
    ]

}

class CoinGeckoManager {
    enum CoinIdError: Error {
        case noMatchingCoinId
    }

    private let disposeBag = DisposeBag()

    private let provider: CoinGeckoProvider
    private let storage: IProviderCoinInfoStorage & IMarketInfoStorage

    init(provider: CoinGeckoProvider, storage: IProviderCoinInfoStorage & IMarketInfoStorage) {
        self.provider = provider
        self.storage = storage
    }

    private func coinIds(coinCodes: [String]) -> Single<[String]> {
        let coinInfosSingle: Single<[ProviderCoinInfoRecord]>
        let coinCodes = coinCodes.map { $0.uppercased() }

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
            providerCoinInfos.map { $0.coinId }
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
                    coinIds: "&ids=\(coinIds.joined(separator: ","))")
        }
    }

    func coinMarketInfoSingle(coinCode: String, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo> {
        coinIds(coinCodes: [coinCode]).flatMap { [weak self] coinIds in
            guard let coinId = coinIds.first, let provider = self?.provider else {
                return Single.error(CoinIdError.noMatchingCoinId)
            }

            return provider.coinMarketInfoSingle(coinCode: coinId, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
        }
    }

}
