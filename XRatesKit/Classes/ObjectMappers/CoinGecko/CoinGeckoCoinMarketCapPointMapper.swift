import HsToolKit

class CoinGeckoCoinMarketCapPointMapper: IApiMapper {
    private let intervalInSeconds: TimeInterval?
    private let minimalPointCount: Int

    init(intervalInSeconds: TimeInterval? = nil, points: Int) {
        self.intervalInSeconds = intervalInSeconds
        minimalPointCount = points
    }

    private func normalize(charts: [CoinMarketPoint]) -> [CoinMarketPoint] {
        guard let intervalInSeconds = intervalInSeconds, charts.count > minimalPointCount else {
            return charts
        }

        // filtering points from last to first use out interval for points
        var nextTs = TimeInterval.greatestFiniteMagnitude
        return charts.reversed().compactMap { point in
            if point.timestamp <= nextTs {
                nextTs = point.timestamp - intervalInSeconds + 180 // 3 minutes
                return point
            } else {
                return nil
            }
        }.reversed()
    }

    func map(statusCode: Int, data: Any?) throws -> [CoinMarketPoint] {
        var charts = [CoinMarketPoint]()

        guard let chartsMap = data as? [String: Any],
                let marketCaps = chartsMap["market_caps"] as? [[Any]],
                let volumes = chartsMap["total_volumes"] as? [[Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        for (index, marketCapArray) in marketCaps.enumerated() {
            if marketCapArray.count == 2 && volumes.count >= index, volumes[index].count == 2,
               let timestamp = marketCapArray[0] as? Int,
               let marketCap = Decimal(convertibleValue: marketCapArray[1]),
               let volume = Decimal(convertibleValue: volumes[index][1]) {
                charts.append(CoinMarketPoint(timestamp: TimeInterval(timestamp/1000), marketCap: marketCap, volume24h: volume))
            }
        }

        return normalize(charts: charts)
    }

}
