import ObjectMapper

struct CryptoCompareHistoricalRateResponse: ImmutableMappable {
    let rateValue: Decimal?

    init(map: Map) throws {
        let rateDataList: [[String: Any]] = try map.value("Data.Data") 
        guard rateDataList.count > 0 else {
            rateValue = nil
            return
        }
        var rate: Decimal = 0
        for rateData in rateDataList {
            if let open = rateData["open"] as? Double, let close = rateData["close"] as? Double {
                rate += NSNumber(value: open + close).decimalValue
            }
        }

        self.rateValue = rate / (Decimal(rateDataList.count) * 2)
    }

}
