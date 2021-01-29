import RxSwift

class CoinMarketsManager {
    private let coinMarketsProvider: ICoinMarketsProvider

    init(coinMarketsProvider: ICoinMarketsProvider) {
        self.coinMarketsProvider = coinMarketsProvider
    }

}

extension CoinMarketsManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int) ->Single<[CoinMarket]> {
        coinMarketsProvider.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinCodes: [String]) ->Single<[CoinMarket]> {
        coinMarketsProvider.coinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coinCodes: coinCodes)
    }

}
