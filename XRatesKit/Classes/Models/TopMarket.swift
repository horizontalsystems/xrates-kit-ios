import Foundation

public struct TopMarket {
    public let coin: XRatesKit.Coin
    public var marketInfo: MarketInfo

    init(coin: XRatesKit.Coin, record: MarketInfoRecord, expirationInterval: TimeInterval) {
        self.coin = coin
        marketInfo = MarketInfo(record: record, expirationInterval: expirationInterval)
    }

}
