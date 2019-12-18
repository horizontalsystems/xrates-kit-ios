import ObjectMapper

struct CryptoCompareChartStatsResponse: ImmutableMappable {
    let chartPoints: [ChartPoint]

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        let data: [String: Any] = try map.value("Data")

        guard let rateDataList = data["Data"] as? [[String: Any]] else {
            throw CryptoCompareError.invalidData
        }

        var chartPoints = [ChartPoint]()

        for rateData in rateDataList {
            if let timestamp = rateData["time"] as? Int, let open = rateData["open"] as? Double, let close = rateData["close"] as? Double {
                let rateValue = NSNumber(value: (open + close) / 2).decimalValue
                chartPoints.append(ChartPoint(timestamp: TimeInterval(timestamp), value: rateValue))
            }
        }

        self.chartPoints = chartPoints
    }

}
