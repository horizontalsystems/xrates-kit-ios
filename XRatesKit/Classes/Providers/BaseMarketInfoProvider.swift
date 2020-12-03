import RxSwift

class BaseMarketInfoProvider {
    private let mainProvider: IMarketInfoProvider
    private let uniswapGraphProvider: IMarketInfoProvider

    init(mainProvider: IMarketInfoProvider, uniswapGraphProvider: IMarketInfoProvider) {
        self.mainProvider = mainProvider
        self.uniswapGraphProvider = uniswapGraphProvider
    }
}

extension BaseMarketInfoProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coins: [XRatesKit.Coin], currencyCode: String) -> Single<[MarketInfoRecord]> {
        var ethereumCoins = [XRatesKit.Coin]()
        var otherCoins = [XRatesKit.Coin]()

        for coin in coins {
            if case .erc20 = coin.type {
                ethereumCoins.append(coin)
            } else if case .ethereum = coin.type {
                ethereumCoins.append(coin)
            } else {
                otherCoins.append(coin)
            }
        }

        return Single.zip(
                mainProvider.getMarketInfoRecords(coins: otherCoins, currencyCode: currencyCode),
                uniswapGraphProvider.getMarketInfoRecords(coins: ethereumCoins, currencyCode: currencyCode)
        ).map { $0 + $1 }
    }

}
