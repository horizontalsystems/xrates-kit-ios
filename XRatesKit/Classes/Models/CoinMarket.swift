import Foundation
import CoinKit

public struct CoinMarket {
    public let coin: XRatesKit.Coin
    public var marketInfo: MarketInfo

    init(coin: XRatesKit.Coin, marketInfo: MarketInfo) {
        self.coin = coin
        self.marketInfo = marketInfo
    }

    init(coin: XRatesKit.Coin, record: MarketInfoRecord, expirationInterval: TimeInterval) {
        self.coin = coin
        marketInfo = MarketInfo(record: record, expirationInterval: expirationInterval)
    }

}
