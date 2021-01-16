extension XRatesKit.CoinType {

    var id: Int {
        switch self {
        case .bitcoin: return 0
        case .litecoin: return 1
        case .bitcoinCash: return 2
        case .dash: return 3
        case .ethereum: return 4
        case .erc20: return 5
        case .binance: return 6
        case .zcash: return 7
        case .eos: return 8
        }
    }

    static func baseType(id: Int) -> Self? {
        switch id {
        case 0: return .bitcoin
        case 1: return .litecoin
        case 2: return .bitcoinCash
        case 3: return .dash
        case 4: return .ethereum
        case 6: return .binance
        case 7: return .zcash
        case 8: return .eos
        default:
            return nil
        }
    }

    var contractAddress: String? {
        if case .erc20(let address) = self {
            return address
        }
        return nil
    }

}
