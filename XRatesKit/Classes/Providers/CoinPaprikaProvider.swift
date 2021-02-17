import Foundation
import HsToolKit
import RxSwift
import Alamofire
import ObjectMapper

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

fileprivate class CoinPaprikaCoinInfoMapper: IApiMapper {
    typealias T = [XRatesKit.Coin]

    private let platformId: String

    init(platformId: String) {
        self.platformId = platformId
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = (data as? [[String: Any]]) else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { dictionary in
            guard let active = dictionary["active"] as? Int, active == 1,
                  let coinId = dictionary["id"] as? String else {
                return nil
            }
            let chunks = coinId.split(separator: "-")
            let code = chunks.first ?? ""
            let title = chunks.dropFirst().joined(separator: " ")

            var coinType: XRatesKit.CoinType?
            if platformId.contains("eth-ethereum"),
               let address = dictionary["address"] as? String {
                coinType = .erc20(address: address)
            }

            return XRatesKit.Coin(code: code.uppercased(), title: title, type: coinType)
        }
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

    private func marketOverviewData(currencyCode: String) -> Single<CoinPaprikaGlobalMarketInfoMapper.MarketPartialInfo> {
        let request = networkManager.session.request("\(baseUrl)/global", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaGlobalMarketInfoMapper())
    }

    private func marketCap(coinId: String = CoinPaprikaProvider.btcId, timestamp: TimeInterval) -> Single<Decimal> {
        let request = networkManager.session.request("\(baseUrl)/coins/\(coinId)/ohlcv/historical?start=\(Int(timestamp))", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaMarketCapMapper())
    }

    private func coinId(coinType: XRatesKit.CoinType) -> String {
        switch coinType {
        case .bitcoin: return "btc-bitcoin"
        case .bitcoinCash: return "bch-bitcoin-cash"
        case .litecoin: return "ltc-litecoin"
        case .ethereum: return "eth-ethereum"
        case .binance: return "bnb-binance-coin"
        case .eos: return "eos-eos"
        case .dash: return "dash-dash"
        case .zcash: return "zec-zcash"
        case .erc20: return "eth-ethereum"
        }
    }

}

extension CoinPaprikaProvider {

    func globalCoinMarketsInfo(currencyCode: String) -> RxSwift.Single<AllMarketInfo> {
        Single.zip(
            marketOverviewData(currencyCode: currencyCode),
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

extension CoinPaprikaProvider: ICoinInfoProvider {

    func coinInfoSingle(platform: XRatesKit.CoinType) -> Single<[XRatesKit.Coin]> {
        let platformId = coinId(coinType: platform)

        let request = networkManager.session.request("\(baseUrl)/contracts/\(platformId)", method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: CoinPaprikaCoinInfoMapper(platformId: platformId))
    }

}
