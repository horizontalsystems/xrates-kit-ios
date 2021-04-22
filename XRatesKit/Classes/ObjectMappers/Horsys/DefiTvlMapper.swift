import HsToolKit

class DefiTvlMapper: IApiMapper {
    typealias T = [DefiTvl]

    private let providerCoinsManager: ProviderCoinsManager
    private let period: String

    init(providerCoinsManager: ProviderCoinsManager, period: String) {
        self.providerCoinsManager = providerCoinsManager
        self.period = period
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return array.compactMap { point in
            guard let coinGeckoId = point["coingecko_id"] as? String,
                  let name = point["name"] as? String,
                  let code = point["code"] as? String,
                  let tvl = Decimal(convertibleValue: point["tvl"]),
                  let tvlDiff = Decimal(convertibleValue: point["tvl_diff_\(period)"]),
                  let coinType = providerCoinsManager.coinTypes(providerId: coinGeckoId, provider: .coinGecko).first else {

                return nil
            }

            let coinData = CoinData(coinType: coinType, code: code, name: name)
            return DefiTvl(data: coinData, tvl: tvl, tvlDiff: tvlDiff)
        }
    }

}
