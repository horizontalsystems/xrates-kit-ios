import ObjectMapper
import HsToolKit

struct CryptoCompareTopMarketInfosResponse: ImmutableMappable {
    let values: [String: [(coin: TopMarketCoin, marketInfo: ResponseMarketInfo)]]

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        var values = [String: [(coin: TopMarketCoin, marketInfo: ResponseMarketInfo)]]()
        let raw = map.JSON

        guard let rawArray = raw["Data"] as? [Any] else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        for marketElement in rawArray {
            guard let marketDictionary = marketElement as? [String: Any],
                  let coinInfoDictionary = marketDictionary["CoinInfo"] as? [String: Any], 
                  let pricesDictionary = marketDictionary["RAW"] as? [String: Any] else {
                throw NetworkManager.ObjectMapperError.mappingError
            }

            guard let coinCode = coinInfoDictionary["Name"] as? String,
                  let coinName = coinInfoDictionary["FullName"] as? String else {
                throw NetworkManager.ObjectMapperError.mappingError
            }

            for (currencyCode, currencyCodeValue) in pricesDictionary {
                if values[currencyCode] == nil {
                    values[currencyCode] = [(coin: TopMarketCoin, marketInfo: ResponseMarketInfo)]()
                }

                guard let currencyCodeDictionary = currencyCodeValue as? [String: Any] else {
                    throw NetworkManager.ObjectMapperError.mappingError
                }

                let marketInfo = try ResponseMarketInfo(JSON: currencyCodeDictionary)

                values[currencyCode]?.append((coin: TopMarketCoin(code: coinCode, title: coinName), marketInfo: marketInfo))
            }
        }

        self.values = values
    }
    
}
