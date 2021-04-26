import HsToolKit

class DefiTvlPointsMapper: IApiMapper {
    typealias T = [DefiTvlPoint]

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { point in
            guard let currencyCode = point["currency_code"] as? String,
                  let timestamp = point["timestamp"] as? Int,
                  let tvl = Decimal(convertibleValue: point["tvl"]) else {

                return nil
            }

            return DefiTvlPoint(timestamp: TimeInterval(timestamp), currencyCode: currencyCode, tvl: tvl)
        }
    }

}
