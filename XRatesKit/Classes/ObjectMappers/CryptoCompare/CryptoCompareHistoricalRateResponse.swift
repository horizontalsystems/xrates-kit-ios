import ObjectMapper
import HsToolKit

class CryptoCompareHistoricalRateResponse: ImmutableMappable {
    let rateValue: Decimal

    required init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        let data: [String: Any] = try map.value("Data") 

        guard let rateDataList = data["Data"] as? [[String: Any]] else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        guard let lastRateData = rateDataList.last else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        guard let value = lastRateData["close"] as? Double else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        rateValue = NSNumber(value: value).decimalValue
    }

}
