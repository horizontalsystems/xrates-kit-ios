public class XRatesErrors {

    public enum HistoricalRate: Error {
        case noValueForMinute
        case noValueForHour
    }

    public enum MarketInfo: Error {
        case invalidResponse
    }

    public enum ChartInfo: Error {
        case noInfo
    }

}
