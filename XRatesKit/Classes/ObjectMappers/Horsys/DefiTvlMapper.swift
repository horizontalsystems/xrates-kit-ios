import HsToolKit

class DefiTvlMapper: IApiMapper {
    typealias T = [DefiTvl]

    private let providerCoinsManager: ProviderCoinsManager

    init(providerCoinsManager: ProviderCoinsManager) {
        self.providerCoinsManager = providerCoinsManager
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
                  let tvlDiff24h = Decimal(convertibleValue: point["tvl_diff_24h"]),
                  let coinType = providerCoinsManager.coinTypes(providerId: coinGeckoId, provider: .coinGecko).first else {

                return nil
            }

            let coinData = CoinData(coinType: coinType, code: code, name: name)
            return DefiTvl(data: coinData, tvl: tvl, tvlDiff: tvlDiff24h)
        }
    }

}
