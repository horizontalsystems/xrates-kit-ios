import HsToolKit

class CoinGeckoMarketChartsMapper: IApiMapper {

    func map(statusCode: Int, data: Any?) throws -> [ChartPoint] {
        var charts = [ChartPoint]()

        guard let chartsMap = data as? [String: Any],
                let rates = chartsMap["prices"] as? [[Any]],
                let volumes = chartsMap["total_volumes"] as? [[Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        for (index, rateArray) in rates.enumerated() {
            if rateArray.count == 2 && volumes.count >= index, volumes[index].count == 2,
               let timestamp = rateArray[0] as? Int,
               let rate = Decimal(convertibleValue: rateArray[1]),
               let volume = Decimal(convertibleValue: volumes[index][1]) {
                charts.append(ChartPoint(timestamp: TimeInterval(timestamp/1000), value: rate, volume: volume))
            }
        }

        return charts
    }

}
