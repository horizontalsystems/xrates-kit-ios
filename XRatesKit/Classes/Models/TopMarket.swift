import Foundation

public struct TopMarket {
    public let coinCode: String
    public let coinName: String
    public var marketInfo: MarketInfo

    init(coin: TopMarketCoin, record: MarketInfoRecord, expirationInterval: TimeInterval) {
        coinCode = coin.code
        coinName = coin.title
        marketInfo = MarketInfo(record: record, expirationInterval: expirationInterval)
    }

}
