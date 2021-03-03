import Foundation
import CoinKit

public struct CoinMarket {
    public let coinData: CoinData
    public var marketInfo: MarketInfo

    init(coinData: CoinData, record: MarketInfoRecord, expirationInterval: TimeInterval) {
        self.coinData = coinData
        marketInfo = MarketInfo(record: record, expirationInterval: expirationInterval)
    }

}
