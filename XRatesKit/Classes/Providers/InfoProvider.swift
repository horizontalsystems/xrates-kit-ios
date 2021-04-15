
protocol IInfoProvider {
    var provider: InfoProvider { get }
    func initProvider()
}

enum InfoProvider: String {
    case CoinGecko
    case Horsys

    var baseUrl: String {
        switch self {
        case .CoinGecko: return "https://api.coingecko.com/api/v3"
        case .Horsys: return "https://markets.horizontalsystems.xyz/api/v1/"
        }
    }

    var requestInterval: TimeInterval {
        switch self {
        case .CoinGecko: return 0.6
        case .Horsys: return 0.15
        }
    }

}
