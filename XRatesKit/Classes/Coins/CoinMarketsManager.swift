import RxSwift

class CoinMarketsManager {
    private let coinMarketsProvider: ICoinMarketsProvider
    private let defiMarketsProvider: ICoinMarketsProvider
    private let coinInfoManager: CoinInfoManager

    init(coinMarketsProvider: ICoinMarketsProvider, defiMarketsProvider: ICoinMarketsProvider, coinInfoManager: CoinInfoManager) {
        self.coinMarketsProvider = coinMarketsProvider
        self.defiMarketsProvider = defiMarketsProvider
        self.coinInfoManager = coinInfoManager
    }

}

extension CoinMarketsManager: ICoinMarketsManager {

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int) ->Single<[CoinMarket]> {
        coinMarketsProvider
            .topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
            .map { [weak self] coinMarkets in
                self?.coinInfoManager.identify(coinMarkets: coinMarkets) ?? []
            }

    }

    func topDefiMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int) ->Single<[CoinMarket]> {
        defiMarketsProvider.topCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coins: [XRatesKit.Coin]) ->Single<[CoinMarket]> {
        var ethBasedCoins = [XRatesKit.Coin]()
        var baseCoins = [XRatesKit.Coin]()

        coins.forEach { coin in
            if case .erc20 = coin.type {
                ethBasedCoins.append(coin)
            } else {
                baseCoins.append(coin)
            }
        }

        let baseSingle = baseCoins.isEmpty ? Single<[CoinMarket]>.just([]) : coinMarketsProvider.coinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coins: baseCoins)
        let ethBasedSingle = ethBasedCoins.isEmpty ? Single<[CoinMarket]>.just([]) : defiMarketsProvider.coinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coins: ethBasedCoins)

        return Single
            .zip(baseSingle, ethBasedSingle)
            .map { $0 + $1 }
    }

}
