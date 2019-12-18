import ObjectMapper

class CryptoCompareHistoricalRateResponse: ImmutableMappable {
    let rateValue: Decimal

    required init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        let data: [String: Any] = try map.value("Data") 

        guard let rateDataList = data["Data"] as? [[String: Any]] else {
            throw CryptoCompareError.invalidData
        }

        guard let lastRateData = rateDataList.last else {
            throw CryptoCompareError.invalidData
        }

        guard let value = lastRateData["close"] as? Double else {
            throw CryptoCompareError.invalidData
        }

        rateValue = NSNumber(value: value).decimalValue
    }

}
