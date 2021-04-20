
protocol IInfoProvider {
    var provider: InfoProvider { get }
    func initProvider()
}

enum InfoProvider: String {
    case coinGecko
    case horsys

    var baseUrl: String {
        switch self {
        case .coinGecko: return "https://api.coingecko.com/api/v3"
        case .horsys: return "https://markets.horizontalsystems.xyz/api/v1/"
        }
    }

    var requestInterval: TimeInterval {
        switch self {
        case .coinGecko: return 0.6
        case .horsys: return 0.15
        }
    }

}
