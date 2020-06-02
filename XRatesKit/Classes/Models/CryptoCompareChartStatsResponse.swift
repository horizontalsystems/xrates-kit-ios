import ObjectMapper
import HsToolKit

struct CryptoCompareChartStatsResponse: ImmutableMappable {
    let timeFrom: TimeInterval
    let chartPoints: [ChartPoint]

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        let data: [String: Any] = try map.value("Data")

        guard let rateDataList = data["Data"] as? [[String: Any]] else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        var chartPoints = [ChartPoint]()

        for rateData in rateDataList {
            if let timestamp = rateData["time"] as? Int, 
               let open = rateData["open"] as? Double, 
               let close = rateData["close"] as? Double,
               let volume = rateData["volumeto"] as? Double {

                let rateValue = NSNumber(value: (open + close) / 2).decimalValue
                let volumeValue = NSNumber(value: volume).decimalValue
                chartPoints.append(ChartPoint(timestamp: TimeInterval(timestamp), value: rateValue, volume: volumeValue))
            }
        }

        self.timeFrom = (data["TimeFrom"] as? TimeInterval) ?? 0
        self.chartPoints = chartPoints
    }

}
