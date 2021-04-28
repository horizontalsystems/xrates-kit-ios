import HsToolKit

class DefiTvlMapper: IApiMapper {
    typealias T = DefiTvl?

    private let providerCoinsManager: ProviderCoinsManager
    private let period: String?

    init(providerCoinsManager: ProviderCoinsManager, period: String?) {
        self.providerCoinsManager = providerCoinsManager
        self.period = period
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let map = data as? [String: Any] else {
            return nil
        }

        guard let coinGeckoId = map["coingecko_id"] as? String,
              let name = map["name"] as? String,
              let code = map["code"] as? String,
              let tvl = Decimal(convertibleValue: map["tvl"]),
              let tvlRank = map["tvl_rank"] as? Int,
              let coinType = providerCoinsManager.coinTypes(providerId: coinGeckoId, provider: .coinGecko).first else {

            return nil
        }

        let tvlDiff: Decimal
        if let period = period {
            guard let diff = Decimal(convertibleValue: map["tvl_diff_\(period)"]) else {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            tvlDiff = diff
        } else {
            tvlDiff = 0
        }

        let coinData = CoinData(coinType: coinType, code: code, name: name)
        return DefiTvl(data: coinData, tvl: tvl, tvlRank: tvlRank, tvlDiff: tvlDiff)
    }

}

class DefiTvlArrayMapper: IApiMapper {
    typealias T = [DefiTvl]

    private let mapper: DefiTvlMapper

    init(providerCoinsManager: ProviderCoinsManager, period: String) {
        mapper = DefiTvlMapper(providerCoinsManager: providerCoinsManager, period: period)
    }

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return try array.compactMap { try mapper.map(statusCode: statusCode, data: $0) }
    }

}
