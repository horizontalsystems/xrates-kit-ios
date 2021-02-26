import RxSwift
import CoinKit

class BaseMarketInfoProvider {
    private let mainProvider: IMarketInfoProvider
    private let uniswapGraphProvider: IMarketInfoProvider

    init(mainProvider: IMarketInfoProvider, uniswapGraphProvider: IMarketInfoProvider) {
        self.mainProvider = mainProvider
        self.uniswapGraphProvider = uniswapGraphProvider
    }
}

extension BaseMarketInfoProvider: IMarketInfoProvider {

    func marketInfoRecords(coinTypes: [CoinType], currencyCode: String) -> Single<[MarketInfoRecord]> {
        var ethereumCoins = [CoinType]()
        var otherCoins = [CoinType]()

        for coinType in coinTypes {
            switch coinType {
            case .erc20, .ethereum: ethereumCoins.append(coinType)
            default: otherCoins.append(coinType)
            }
        }

        return Single.zip(
                mainProvider.marketInfoRecords(coinTypes: otherCoins, currencyCode: currencyCode),
                uniswapGraphProvider.marketInfoRecords(coinTypes: ethereumCoins, currencyCode: currencyCode)
        ).map { $0 + $1 }
    }

}
