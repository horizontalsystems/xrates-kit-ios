import HsToolKit

class GlobalCoinMarketPointMapper: IApiMapper {
    typealias T = [GlobalCoinMarketPoint]

    private let timePeriod: TimePeriod

    init(timePeriod: TimePeriod) {
        self.timePeriod = timePeriod
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { point in
            guard let currencyCode = point["currency_code"] as? String,
                  let timestamp = point["timestamp"] as? Double else {

                return nil
            }

            let volume24h = Decimal(convertibleValue: point["volume24h"]) ?? 0
            let marketCap = Decimal(convertibleValue: point["market_cap"]) ?? 0
            let dominanceBtc = Decimal(convertibleValue: point["dominance_btc"]) ?? 0
            let marketCapDefi = Decimal(convertibleValue: point["market_cap_defi"]) ?? 0
            let tvl = Decimal(convertibleValue: point["tvl"]) ?? 0

            return GlobalCoinMarketPoint(
                    currencyCode: currencyCode,
                    timePeriod: timePeriod,
                    timestamp: timestamp,
                    volume24h: volume24h,
                    marketCap: marketCap,
                    dominanceBtc: dominanceBtc,
                    marketCapDefi: marketCapDefi,
                    tvl: tvl)
        }
    }

}
