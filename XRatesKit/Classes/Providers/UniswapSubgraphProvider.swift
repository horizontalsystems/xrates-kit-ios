import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper

class UniswapSubgraphProvider {
    static private let baseFiatCurrency = "USD"
    static private let ETHCoinCode = "ETH"
    static private let WETHTokenCode = "WETH"
    static private let WETHTokenAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

    private let fiatXRatesProvider: IFiatXRatesProvider
    private let networkManager: NetworkManager
    private let baseUrl: String

    init(fiatXRatesProvider: IFiatXRatesProvider, networkManager: NetworkManager, baseUrl: String) {
        self.fiatXRatesProvider = fiatXRatesProvider
        self.networkManager = networkManager
        self.baseUrl = baseUrl
    }

    private func tokenAddresses(coins: [XRatesKit.Coin]) -> [String] {
        coins.compactMap { coin in
            if case .erc20(let address) = coin.type {
                return address.lowercased()
            }

            if case .ethereum = coin.type {
                return UniswapSubgraphProvider.WETHTokenAddress
            }

            return nil
        }
    }

    private func request<T: ImmutableMappable>(query: String) -> Single<T> {
        let request = networkManager.session.request(baseUrl, method: .post, parameters: ["query": "{\(query)}"], encoding: JSONEncoding())

        return networkManager.single(request: request)
    }

    private func ratesSingle(addresses: [String], timestamp: Int) -> Single<UniswapSubgraphRatesResponse> {
        let query = addresses.enumerated().map { (index, address) in
            """
            o\(index): tokenDayDatas(
                first: 1,
                orderBy: date,
                orderDirection: desc,
                where: {  
                  date_lte: \(timestamp),
                  token: "\(address)"
                }
            ) { 
                token { symbol, derivedETH },
                priceUSD
            }
            """
        }.joined(separator: ", ")

        return request(query: query)
    }

    private func ethPriceSingle() -> Single<UniswapSubgraphEthPriceResponse> {
        let query = "bundle(id:1) {ethPriceUSD: ethPrice}"
        return request(query: query)
    }

}

extension UniswapSubgraphProvider: IMarketInfoProvider {

    func getMarketInfoRecords(coins: [XRatesKit.Coin], currencyCode: String) -> Single<[MarketInfoRecord]> {
        let addresses = tokenAddresses(coins: coins)

        return Single.zip(
                ratesSingle(addresses: addresses, timestamp: Int(Date().timeIntervalSince1970) - 24 * 60 * 60),
                ethPriceSingle(),
                currencyCode == UniswapSubgraphProvider.baseFiatCurrency ? Single.just(1.0) :
                        fiatXRatesProvider.latestFiatXRates(sourceCurrency: UniswapSubgraphProvider.baseFiatCurrency, targetCurrency: currencyCode)
        ).map { [weak self] (
                rates: UniswapSubgraphRatesResponse,
                ethPriceResponse: UniswapSubgraphEthPriceResponse,
                fiatRate: Decimal) in
            guard let provider = self else {
                return []
            }

            var ethPrice = ethPriceResponse.usdPrice
            if (currencyCode != UniswapSubgraphProvider.baseFiatCurrency) {
                ethPrice *= fiatRate
            }

            var marketInfos = [MarketInfoRecord]()

            for rate in rates.values {
                let coinCode = rate.coinCode == UniswapSubgraphProvider.WETHTokenCode ? UniswapSubgraphProvider.ETHCoinCode : rate.coinCode
                let latestPrice = rate.latestPriceInETH * ethPrice
                let dayOpenUSDPrice = rate.dayStartPriceInUSD ?? latestPrice
                let dayOpenFiatPrice = fiatRate * dayOpenUSDPrice
                let diff = dayOpenFiatPrice > 0 ? ((latestPrice - dayOpenFiatPrice) * 100) / dayOpenFiatPrice : 0

                marketInfos.append(MarketInfoRecord(
                        coinCode: coinCode,
                        currencyCode: currencyCode,
                        rate: latestPrice,
                        openDay: dayOpenFiatPrice,
                        diff: diff,
                        volume: 0,
                        marketCap: 0,
                        supply: 0
                ))
            }

            return marketInfos
        }
    }

}
