import ObjectMapper

class CryptoCompareHistoricalRateResponse: ImmutableMappable {
    let rateValue: Decimal

    required init(map: Map) throws {
        let data = try CryptoCompareResponse.parseData(map: map)

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
