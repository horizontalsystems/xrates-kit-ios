import Foundation
import HsToolKit
import RxSwift
import Alamofire

fileprivate class CoinGeckoTopMarketMapper: IApiMapper {
    typealias T = [TopMarket]

    private let currencyCode: String
    private let fetchDiffPeriod: TimePeriod
    private let expirationInterval: TimeInterval

    init(currencyCode: String, fetchDiffPeriod: TimePeriod, expirationInterval: TimeInterval) {
        self.currencyCode = currencyCode
        self.fetchDiffPeriod = fetchDiffPeriod
        self.expirationInterval = expirationInterval
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { tokenData in
            guard let coinCode = tokenData["symbol"] as? String,
                  let coinTitle = tokenData["name"] as? String else {

                return nil
            }

            let rate = Decimal(convertibleValue: tokenData["current_price"]) ?? 0
            let rateOpenDay = Decimal(convertibleValue: tokenData["price_change_24h"]) ?? 0
            let supply = Decimal(convertibleValue: tokenData["circulating_supply"]) ?? 0
            let volume = Decimal(convertibleValue: tokenData["total_volume"]) ?? 0
            let marketCap = Decimal(convertibleValue: tokenData["market_cap"]) ?? 0

            let priceDiffFieldName: String
            switch fetchDiffPeriod {
            case .hour1: priceDiffFieldName = "price_change_percentage_1h_in_currency"
            case .day7: priceDiffFieldName = "price_change_percentage_7d_in_currency"
            case .day30: priceDiffFieldName = "price_change_percentage_30d_in_currency"
            case .year1: priceDiffFieldName = "price_change_percentage_1y_in_currency"
            default: priceDiffFieldName = "price_change_percentage_24h"
            }

            let rateDiffPeriod = Decimal(convertibleValue: tokenData[priceDiffFieldName]) ?? 0
            let rateDiff24h = Decimal(convertibleValue: tokenData["price_change_percentage_24h"]) ?? 0

            let record = MarketInfoRecord(
                    coinCode: coinCode,
                    currencyCode: currencyCode,
                    rate: rate, openDay: rateOpenDay,
                    diff: rateDiff24h,
                    volume: volume,
                    marketCap: marketCap,
                    supply: supply,
                    rateDiffPeriod: rateDiffPeriod
            )

            return TopMarket(coin: XRatesKit.Coin(code: coinCode, title: coinTitle), record: record, expirationInterval: expirationInterval)
        }
    }

}

class CoinGeckoProvider {
    private let baseUrl = "https://api.coingecko.com/api/v3"

    private let networkManager: NetworkManager
    private let expirationInterval: TimeInterval

    init(networkManager: NetworkManager, expirationInterval: TimeInterval) {
        self.networkManager = networkManager
        self.expirationInterval = expirationInterval
    }

}

extension CoinGeckoProvider: ITopMarketsProvider {

    func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[TopMarket]> {
        let url = "\(baseUrl)/coins/markets?vs_currency=\(currencyCode)&price_change_percentage=1h,7d,30d,1y&order=market_cap_desc&per_page=\(itemCount)"

        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoTopMarketMapper(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)
        return networkManager.single(request: request, mapper: mapper)
    }

}
