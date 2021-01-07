import ObjectMapper

class UniswapGraphToken {
    let tokenAddress: String
    let coinCode: String
    let coinTitle: String
    let latestRateInETH: Decimal
    let volumeInUSD: Decimal
    let totalLiquidity: Decimal

    init(tokenAddress: String, coinCode: String, coinTitle: String, latestRateInETH: Decimal, volumeInUSD: Decimal, totalLiquidity: Decimal) {
        self.tokenAddress = tokenAddress
        self.coinCode = coinCode
        self.coinTitle = coinTitle
        self.latestRateInETH = latestRateInETH
        self.volumeInUSD = volumeInUSD
        self.totalLiquidity = totalLiquidity
    }

}

class UniswapGraphTokensResponse: ImmutableMappable {
    let tokens: [UniswapGraphToken]
    let ethPriceInUSD: Decimal

    required init(map: Map) throws {
        let data: [String: Any] = try map.value("data")
        guard let bundles = data["bundles"] as? [[String: String]],
              let tokens = data["tokens"] as? [[String: String]] else {
            throw MapError(key: "data", currentValue: data, reason: "Can't parse data")
        }

        guard let ethPriceInUSDString = bundles.first?["ethPriceUSD"],
                let ethPriceInUSD = Decimal(string: ethPriceInUSDString) else {

            throw MapError(key: "ethPriceUSD", currentValue: bundles, reason: "Error parsing Uniswap Ethprice data")
        }

        self.ethPriceInUSD = ethPriceInUSD

        self.tokens = tokens.compactMap { dictionary in
            guard let tokenAddress = dictionary["id"],
            let coinCode = dictionary["symbol"],
            let coinTitle = dictionary["name"],
            let latestRateInETH = dictionary["derivedETH"].map({ Decimal(string: $0) }) ?? 0,
            let volumeInUSD = dictionary["tradeVolumeUSD"].map({ Decimal(string: $0) }) ?? 0,
            let totalLiquidity = dictionary["totalLiquidity"].map({ Decimal(string: $0) }) ?? 0 else {
                return nil
            }

            return UniswapGraphToken(
                    tokenAddress: tokenAddress,
                    coinCode: coinCode,
                    coinTitle: coinTitle,
                    latestRateInETH: latestRateInETH,
                    volumeInUSD: volumeInUSD,
                    totalLiquidity: totalLiquidity)
        }
    }

}
