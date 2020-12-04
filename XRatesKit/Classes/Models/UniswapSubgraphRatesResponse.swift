import ObjectMapper
import HsToolKit

struct UniswapSubgraphRatesResponse: ImmutableMappable {
    let values: [(coinCode: String, latestPriceInETH: Decimal, dayStartPriceInUSD: Decimal)]

    init(map: Map) throws {
        let raw = map.JSON

        guard let ratesDictionary = raw["data"] as? [String: Any] else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        var values = [(coinCode: String, latestPriceInETH: Decimal, dayStartPriceInUSD: Decimal)]()

        for (_, rateObject) in ratesDictionary {
            guard let rateArray = rateObject as? [Any],
                  let rateDictionary = rateArray.first as? [String: Any],
                  let dayStartPriceString = rateDictionary["priceUSD"] as? String,
                  let dayStartPrice = Decimal(string: dayStartPriceString),
                  let tokenDictionary = rateDictionary["token"] as? [String: Any],
                  let coinCode = tokenDictionary["symbol"] as? String,
                  let latestPriceString = tokenDictionary["derivedETH"] as? String,
                  let latestPrice = Decimal(string: latestPriceString) else {
                continue
            }

            values.append((coinCode: coinCode, latestPriceInETH: latestPrice, dayStartPriceInUSD: dayStartPrice))
        }

        self.values = values
    }

}
