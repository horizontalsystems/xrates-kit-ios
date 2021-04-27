enum InfoProvider: String {
    case cryptoCompare
    case coinGecko
    case horsys

    var baseUrl: String {
        switch self {
        case .cryptoCompare: return "https://min-api.cryptocompare.com"
        case .coinGecko: return "https://api.coingecko.com/api/v3"
        case .horsys: return "https://markets.horizontalsystems.xyz/api/v1/"
        }
    }

    var requestInterval: TimeInterval {
        switch self {
        case .cryptoCompare: return 0
        case .coinGecko: return 0.6
        case .horsys: return 0.15
        }
    }

}
