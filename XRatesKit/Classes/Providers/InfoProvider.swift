
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

}
