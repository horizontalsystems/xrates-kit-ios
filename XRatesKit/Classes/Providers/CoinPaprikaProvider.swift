import Foundation
import HsToolKit
import RxSwift
import Alamofire
import ObjectMapper

fileprivate class CoinPaprikaGlobalMarketInfoMapper: IApiMapper {
    typealias T = GlobalMarketInfo

    private let currencyCode: String

    init(currencyCode: String) {
        self.currencyCode = currencyCode
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let dictionary = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        let volume24h = Decimal(convertibleValue: dictionary["volume_24h_usd"]) ?? 0
        let volume24hDiff = Decimal(convertibleValue: dictionary["volume_24h_change_24h"]) ?? 0
        let marketCap = Decimal(convertibleValue: dictionary["market_cap_usd"]) ?? 0
        let marketCapDiff = Decimal(convertibleValue: dictionary["market_cap_change_24h"]) ?? 0
        let btcDominance = Decimal(convertibleValue: dictionary["bitcoin_dominance_percentage"]) ?? 0

        return GlobalMarketInfo(currencyCode: currencyCode,
                volume24h: volume24h,
                volume24hDiff24h: volume24hDiff,
                marketCap: marketCap,
                marketCapDiff24h: marketCapDiff,
                btcDominance: btcDominance,
                btcDominanceDiff24h: 0,
                defiMarketCap: 0,
                defiMarketCapDiff24h: 0,
                defiTvl: 0,
                defiTvlDiff24h: 0)
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

    private func marketOverviewData(currencyCode: String) -> Single<GlobalMarketInfo> {
        let request = networkManager.session.request("\(baseUrl)/global", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaGlobalMarketInfoMapper(currencyCode: currencyCode))
    }

    private func marketCap(coinId: String = CoinPaprikaProvider.btcId, timestamp: TimeInterval) -> Single<Decimal> {
        let request = networkManager.session.request("\(baseUrl)/coins/\(coinId)/ohlcv/historical?start=\(Int(timestamp))", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaMarketCapMapper())
    }

}

extension CoinPaprikaProvider: IGlobalMarketInfoProvider {

    func globalMarketInfo(currencyCode: String) -> RxSwift.Single<GlobalMarketInfo> {
        Single.zip(
            marketOverviewData(currencyCode: currencyCode),
            marketCap(timestamp: Date().timeIntervalSince1970 - Self.hours24InSeconds)
        ) { globalMarketInfo, btcMarketCap in
            let openingMarketCap = 100 * globalMarketInfo.marketCap / (globalMarketInfo.marketCapDiff24h + 100)
            let openingBtcDominanceDiff = (100 * btcMarketCap) / openingMarketCap
            globalMarketInfo.btcDominanceDiff24h = globalMarketInfo.btcDominance - openingBtcDominanceDiff

            return globalMarketInfo
        }
    }

}