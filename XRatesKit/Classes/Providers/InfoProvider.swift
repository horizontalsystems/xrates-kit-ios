
protocol IInfoProvider {
    var provider: InfoProvider { get }
    func initProvider()
}

enum InfoProvider: String {
    case CryptoCompare
    case CoinPaprika
    case CoinGecko
    case GraphNetwork
    case Horsys

    var baseUrl: String {
        switch self {
        case .CryptoCompare: return "https://min-api.cryptocompare.com"
        case .CoinPaprika: return "https://api.coinpaprika.com/v1"
        case .CoinGecko: return "https://api.coingecko.com/api/v3"
        case .GraphNetwork: return "https://api.thegraph.com/subgraphs/name"
        case .Horsys: return "https://info.horizontalsystems.xyz/api/v1"
        }
    }

    var requestInterval: TimeInterval {
        switch self {
        case .CryptoCompare: return 0
        case .CoinPaprika: return 0.15
        case .CoinGecko: return 0.6
        case .GraphNetwork: return 0
        case .Horsys: return 0.15
        }
    }

}
