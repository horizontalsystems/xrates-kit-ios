import Foundation

public struct TopMarketInfo {
    public let coinCode: String
    public let coinName: String
    public let marketInfo: MarketInfo

    init(record: TopMarketInfoRecord, expirationInterval: TimeInterval) {
        coinCode = record.coinCode
        coinName = record.coinName

        marketInfo = MarketInfo(
                timestamp: record.timestamp,
                rate: record.rate,
                open24hour: record.open24Hour,
                diff: record.diff,
                volume: record.volume,
                marketCap: record.marketCap,
                supply: record.supply,
                expirationInterval: expirationInterval
        )
    }

}
