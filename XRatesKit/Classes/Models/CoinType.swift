extension XRatesKit.CoinType: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        if rawValue.contains("erc20"), let address = rawValue.split(separator: ":").last {
            self = .erc20(address: String(address))
            return
        }

        var type: Self?

        switch rawValue {
        case "bitcoin": type = .bitcoin
        case "litecoin": type = .litecoin
        case "bitcoinCash": type = .bitcoinCash
        case "dash": type = .dash
        case "ethereum": type = .ethereum
        case "binance": type = .binance
        case "zcash": type = .zcash
        case "eos": type = .eos
        default: type = nil
        }

        guard let coinType = type else {
            return nil
        }

        self = coinType
    }

    public var rawValue: RawValue {
        switch self {
        case .bitcoin: return "bitcoin"
        case .litecoin: return "litecoin"
        case .bitcoinCash: return "bitcoinCash"
        case .dash: return "dash"
        case .ethereum: return "ethereum"
        case .erc20(let address): return "erc20:\(address)"
        case .binance: return "binance"
        case .zcash: return "zcash"
        case .eos: return "eos"
        }
    }

}
