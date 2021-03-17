import Foundation
import CoinKit

public struct CoinMarket {
    public let coinData: CoinData
    public let marketInfo: MarketInfo

    init(coinData: CoinData, marketInfo: MarketInfo) {
        self.coinData = coinData
        self.marketInfo = marketInfo
    }

}
