import Foundation

struct GlobalCoinMarketInfo {
    let currencyCode: String
    let timestamp: TimeInterval
    let timePeriod: TimePeriod

    let points: [GlobalCoinMarketPoint]
}
