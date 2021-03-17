import Foundation
import HsToolKit
import RxSwift
import Alamofire
import ObjectMapper
import CoinKit

fileprivate class CoinPaprikaGlobalMarketInfoMapper: IApiMapper {
    struct MarketPartialInfo {
            let volume24h: Decimal
            let volume24hDiff24h: Decimal
            let marketCap: Decimal
            let marketCapDiff24h: Decimal
            let btcDominance: Decimal
    }
    typealias T = MarketPartialInfo

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let dictionary = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        let volume24h = Decimal(convertibleValue: dictionary["volume_24h_usd"]) ?? 0
        let volume24hDiff = Decimal(convertibleValue: dictionary["volume_24h_change_24h"]) ?? 0
        let marketCap = Decimal(convertibleValue: dictionary["market_cap_usd"]) ?? 0
        let marketCapDiff = Decimal(convertibleValue: dictionary["market_cap_change_24h"]) ?? 0
        let btcDominance = Decimal(convertibleValue: dictionary["bitcoin_dominance_percentage"]) ?? 0

        return MarketPartialInfo(
                volume24h: volume24h,
                volume24hDiff24h: volume24hDiff,
                marketCap: marketCap,
                marketCapDiff24h: marketCapDiff,
                btcDominance: btcDominance
        )
    }
}

fileprivate class CoinPaprikaMarketCapMapper: IApiMapper {
    typealias T = Decimal

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let dictionary = (data as? [[String: Any]])?.first,
              let marketCap = Decimal(convertibleValue: dictionary["market_cap"]) else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return marketCap
    }

}

class CoinPaprikaProvider {
    private static let btcId = "btc-bitcoin"
    private static let hours24InSeconds: TimeInterval = 86400
    private let baseUrl = "https://api.coinpaprika.com/v1"

    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    private func request<T: ImmutableMappable>(query: String) -> Single<T> {
        let request = networkManager.session.request(baseUrl, method: .post, parameters: ["query": "{\(query)}"], encoding: JSONEncoding())

        return networkManager.single(request: request)
    }

    private func marketOverviewData() -> Single<CoinPaprikaGlobalMarketInfoMapper.MarketPartialInfo> {
        let request = networkManager.session.request("\(baseUrl)/global", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaGlobalMarketInfoMapper())
    }

    private func marketCap(coinId: String = CoinPaprikaProvider.btcId, timestamp: TimeInterval) -> Single<Decimal> {
        let request = networkManager.session.request("\(baseUrl)/coins/\(coinId)/ohlcv/historical?start=\(Int(timestamp))", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaMarketCapMapper())
    }

}

extension CoinPaprikaProvider {

    func globalCoinMarketsInfo() -> RxSwift.Single<AllMarketInfo> {
        Single.zip(
            marketOverviewData(),
            marketCap(timestamp: Date().timeIntervalSince1970 - Self.hours24InSeconds)
        ) { partialOverview, btcMarketCap in
            let openingMarketCap = 100 * partialOverview.marketCap / (partialOverview.marketCapDiff24h + 100)
            let openingBtcDominanceDiff = (100 * btcMarketCap) / openingMarketCap

            return AllMarketInfo(
                    volume24h: partialOverview.volume24h,
                    volume24hDiff24h: partialOverview.volume24hDiff24h,
                    marketCap: partialOverview.marketCap,
                    marketCapDiff24h: partialOverview.marketCapDiff24h,
                    btcDominance: partialOverview.btcDominance,
                    btcDominanceDiff24h: partialOverview.btcDominance - openingBtcDominanceDiff
            )
        }
    }

}
