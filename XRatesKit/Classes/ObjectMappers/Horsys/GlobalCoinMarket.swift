import Foundation

public struct GlobalCoinMarket {
        public let currencyCode: String
        public let volume24h: Decimal
        public let volume24hDiff24h: Decimal
        public let marketCap: Decimal
        public let marketCapDiff24h: Decimal
        public let btcDominance: Decimal
        public let btcDominanceDiff24h: Decimal
        public let defiMarketCap: Decimal
        public let defiMarketCapDiff24h: Decimal
        public let defiTvl: Decimal
        public let defiTvlDiff24h: Decimal
        public let globalCoinMarketPoints: [GlobalCoinMarketPoint]


    private static func calculateDiff(_ sourceValue: Decimal, _ targetValue: Decimal) -> Decimal {
        guard !sourceValue.isZero else {
            return 0
        }

        return (targetValue - sourceValue) * 100 / sourceValue
    }


    init(currencyCode: String, points: [GlobalCoinMarketPoint]) {
        self.currencyCode = currencyCode
        globalCoinMarketPoints = points

        guard let first = points.first, let last = points.last else {
            volume24h = 0
            volume24hDiff24h = 0
            marketCap = 0
            marketCapDiff24h = 0
            btcDominance = 0
            btcDominanceDiff24h = 0
            defiMarketCap = 0
            defiMarketCapDiff24h = 0
            defiTvl = 0
            defiTvlDiff24h = 0

            return
        }

        marketCap = last.marketCap
        marketCapDiff24h = Self.calculateDiff(first.marketCap, marketCap)

        defiMarketCap = last.marketCapDefi
        defiMarketCapDiff24h = Self.calculateDiff(first.marketCapDefi, defiMarketCap)

        volume24h = last.volume24h
        volume24hDiff24h = Self.calculateDiff(first.volume24h, volume24h)

        btcDominance = last.dominanceBtc
        btcDominanceDiff24h = Self.calculateDiff(first.dominanceBtc, btcDominance)

        defiTvl = last.tvl
        defiTvlDiff24h = Self.calculateDiff(first.tvl, defiTvl)
    }

}
