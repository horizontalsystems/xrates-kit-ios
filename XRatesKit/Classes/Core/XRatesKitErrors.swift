public class XRatesErrors {

    public enum MarketInfo: Error {
        case invalidResponse
    }

    public enum ChartInfo: Error {
        case noInfo
    }

}
