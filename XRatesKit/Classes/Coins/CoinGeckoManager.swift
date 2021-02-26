import RxSwift
import CoinKit

class CoinGeckoManager {
    private let disposeBag = DisposeBag()

    private let provider: CoinGeckoProvider
    private let storage: IMarketInfoStorage
    private let coinInfoManager: CoinInfoManager

    init(coinInfoManager: CoinInfoManager, provider: CoinGeckoProvider, storage: IMarketInfoStorage) {
        self.provider = provider
        self.storage = storage
        self.coinInfoManager = coinInfoManager
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
        let coinInfoRecord = coinInfoManager.coinInfo(coinType: coinType)

        return provider.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes)
                .map { coinInfoResponse in
                    var links = [LinkType: String]()

                    for linkType in LinkType.allCases {
                        links[linkType] = coinInfoRecord?.links[linkType] ?? coinInfoResponse.links[linkType] ?? ""
                    }

                    let coinInfo = CoinInfo(
                            code: coinInfoRecord?.code ?? "",
                            name: coinInfoRecord?.name ?? "",
                            description: coinInfoRecord?.description ?? coinInfoResponse.description,
                            links: links,
                            rating: coinInfoRecord?.rating,
                            categories: coinInfoRecord?.categories ?? [],
                            platforms: coinInfoResponse.platforms
                    )

                    return CoinMarketInfo(
                            coinType: coinType,
                            currencyCode: currencyCode,
                            rate: coinInfoResponse.rate,
                            rateHigh24h: coinInfoResponse.rateHigh24h,
                            rateLow24h: coinInfoResponse.rateLow24h,
                            totalSupply: coinInfoResponse.totalSupply,
                            circulatingSupply: coinInfoResponse.circulatingSupply,
                            volume24h: coinInfoResponse.volume24h,
                            marketCap: coinInfoResponse.marketCap,
                            marketCapDiff24h: coinInfoResponse.marketCapDiff24h,
                            info: coinInfo,
                            rateDiffs: coinInfoResponse.rateDiffs
                    )
                }
    }

}
