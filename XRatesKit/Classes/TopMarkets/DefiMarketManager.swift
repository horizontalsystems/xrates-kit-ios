import RxSwift
import CoinKit

class DefiMarketManager {
    private let coinGeckoProvider: CoinGeckoProvider
    private let defiMarketsProvider: IDefiMarketsProvider

    init(coinGeckoProvider: CoinGeckoProvider, defiMarketsProvider: IDefiMarketsProvider) {
        self.coinGeckoProvider = coinGeckoProvider
        self.defiMarketsProvider = defiMarketsProvider
    }

}

extension DefiMarketManager {

    func topDefiMarkets(currency: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        coinGeckoProvider.topCoinMarketsSingle(currencyCode: currency, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount, defiFilter: true)
    }

    func topDefiTvl(currency: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[DefiTvl]> {
        defiMarketsProvider.topDefiTvl(currencyCode: currency, timePeriod: fetchDiffPeriod, itemCount: itemCount)
    }

    func defiTvl(coinType: CoinType, currencyCode: String) -> Single<DefiTvl?> {
        defiMarketsProvider.defiTvl(coinType: coinType, currencyCode: currencyCode)
    }

    func defiTvlPoints(coinType: CoinType, currencyCode: String, timePeriod: TimePeriod) -> Single<[DefiTvlPoint]> {
        defiMarketsProvider.defiTvlPoints(coinType: coinType, currencyCode: currencyCode, timePeriod: timePeriod)
    }

}