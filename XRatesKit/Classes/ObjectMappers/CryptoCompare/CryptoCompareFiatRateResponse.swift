import ObjectMapper
import HsToolKit

struct CryptoCompareFiatRateResponse: ImmutableMappable {
    let rate: Decimal

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        let raw = map.JSON

        guard let rateDictionary = raw as? [String: Any],
              let firstRate = rateDictionary.first,
              let rateDouble = firstRate.value as? Double else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        rate = Decimal(rateDouble)
    }

}
