public class XRatesErrors {

    public enum LatestRateProvider: Error {
        case allProvidersReturnError
    }

    public enum HistoricalRate: Error {
        case noValueForMinute
        case noValueForHour
    }

}