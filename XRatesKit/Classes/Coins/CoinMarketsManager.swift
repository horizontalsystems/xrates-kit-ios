import RxSwift

class CoinMarketsManager {
    private let coinMarketsProvider: ICoinMarketsProvider

    init(coinMarketsProvider: ICoinMarketsProvider, defiMarketsProvider: ICoinMarketsProvider) {
        self.coinMarketsProvider = coinMarketsProvider
    }

}

extension CoinMarketsManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int) ->Single<[CoinMarket]> {
        coinMarketsProvider.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coins: [XRatesKit.Coin]) ->Single<[CoinMarket]> {
        coinMarketsProvider.coinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coins: coins)
    }

}
