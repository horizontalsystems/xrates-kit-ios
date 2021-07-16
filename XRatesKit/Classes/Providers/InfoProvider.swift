enum InfoProvider: String {
    case cryptoCompare
    case coinGecko
    case horsys
    case defiYield

    var baseUrl: String {
        switch self {
        case .cryptoCompare: return "https://min-api.cryptocompare.com"
        case .coinGecko: return "https://api.coingecko.com/api/v3"
        case .horsys: return "https://markets.horizontalsystems.xyz/api/v1/"
        case .defiYield: return "https://api.safe.defiyield.app"
        }
    }

    var requestInterval: TimeInterval {
        switch self {
        case .cryptoCompare: return 0
        case .coinGecko: return 0.6
        case .horsys: return 0.15
        case .defiYield: return 0.15
        }
    }

}
