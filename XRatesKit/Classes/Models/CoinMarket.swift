import Foundation
import CoinKit

public struct CoinMarket {
    public let coinType: CoinType
    public let coinCode: String
    public let coinTitle: String
    public var marketInfo: MarketInfo

    init(coinType: CoinType, coinCode: String, coinTitle: String, marketInfo: MarketInfo) {
        self.coinType = coinType
        self.coinCode = coinCode
        self.coinTitle = coinTitle
        self.marketInfo = marketInfo
    }

    init(coinType: CoinType, coinCode: String, coinTitle: String, record: MarketInfoRecord, expirationInterval: TimeInterval) {
        self.coinType = coinType
        self.coinCode = coinCode
        self.coinTitle = coinTitle
        marketInfo = MarketInfo(record: record, expirationInterval: expirationInterval)
    }

}
