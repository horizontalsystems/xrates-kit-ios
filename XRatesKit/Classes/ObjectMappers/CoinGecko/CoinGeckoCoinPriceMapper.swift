import HsToolKit
import CoinKit

class CoinGeckoCoinPriceMapper: IApiMapper {
    typealias T = [LatestRateRecord]

    private let coinTypesMap: [String: [CoinType]]
    private let currencyCode: String

    init(coinTypesMap: [String: [CoinType]], currencyCode: String) {
        self.coinTypesMap = coinTypesMap
        self.currencyCode = currencyCode
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: [String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        var response = T()
        let timestamp = Date().timeIntervalSince1970
        let currencyLowercase = currencyCode.lowercased()

        for (coinId, rateMap) in map {
            guard let rate = Decimal(convertibleValue: rateMap[currencyLowercase]),
                  let diff = Decimal(convertibleValue: rateMap["\(currencyLowercase)_24h_change"]) else {
                continue
            }

            coinTypesMap[coinId]?.forEach { coinType in
                response.append(LatestRateRecord(coinType: coinType, currencyCode: currencyCode, rate: rate, rateDiff24h: diff, timestamp: timestamp))
            }
        }

        return response
    }

}
