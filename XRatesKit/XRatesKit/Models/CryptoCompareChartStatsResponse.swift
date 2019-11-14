import ObjectMapper

struct CryptoCompareChartStatsResponse: ImmutableMappable {
    let chartPoints: [ChartPoint]

    init(map: Map) throws {
        let data = try CryptoCompareResponse.parseData(map: map)

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
