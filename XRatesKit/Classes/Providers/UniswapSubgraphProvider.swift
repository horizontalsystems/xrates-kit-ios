import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper

class UniswapSubgraphProvider {
    static private let baseFiatCurrency = "USD"
    static private let ETHCoinCode = "ETH"
    static private let WETHTokenCode = "WETH"
    static private let WETHTokenAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

    private let provider = InfoProvider.GraphNetwork
    private let subUrl = "/uniswap/uniswap-v2"

    private let fiatXRatesProvider: IFiatXRatesProvider
    private let ethBlocksGraphProvider: EthBlocksGraphProvider
    private let networkManager: NetworkManager
    private let expirationInterval: TimeInterval

    init(fiatXRatesProvider: IFiatXRatesProvider, networkManager: NetworkManager, expirationInterval: TimeInterval) {
        self.fiatXRatesProvider = fiatXRatesProvider
        ethBlocksGraphProvider = EthBlocksGraphProvider(networkManager: networkManager)
        self.networkManager = networkManager
        self.expirationInterval = expirationInterval
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
        let request = networkManager.session.request(provider.baseUrl + subUrl, method: .post, parameters: ["query": "{\(query)}"], encoding: JSONEncoding())

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

    private func topTokensSingle(itemCount: Int, blockHeight: Int? = nil) -> Single<UniswapGraphTokensResponse> {
        request(query: GraphQueryBuilder.topTokens(itemCount: itemCount, blockHeight: blockHeight))
    }

    private func coinMarketsSingle(tokenAddresses: [String], blockHeight: Int? = nil) -> Single<UniswapGraphTokensResponse> {
        request(query: GraphQueryBuilder.coinMarkets(tokenAddresses: tokenAddresses, blockHeight: blockHeight))
    }

}

extension UniswapSubgraphProvider: IMarketInfoProvider {

    func marketInfoRecords(coins: [XRatesKit.Coin], currencyCode: String) -> Single<[MarketInfoRecord]> {
        guard !coins.isEmpty else {
            return Single.just([])
        }

        let addresses = tokenAddresses(coins: coins)

        return Single.zip(
                ratesSingle(addresses: addresses, timestamp: Int(Date().timeIntervalSince1970) - 24 * 60 * 60),
                ethPriceSingle(),
                currencyCode == UniswapSubgraphProvider.baseFiatCurrency ? Single.just(1.0) :
                        fiatXRatesProvider.latestFiatXRates(sourceCurrency: UniswapSubgraphProvider.baseFiatCurrency, targetCurrency: currencyCode)
        ).map { (rates: UniswapSubgraphRatesResponse,
                ethPriceResponse: UniswapSubgraphEthPriceResponse,
                fiatRate: Decimal) in

            var ethPrice = ethPriceResponse.usdPrice
            if (currencyCode != UniswapSubgraphProvider.baseFiatCurrency) {
                ethPrice *= fiatRate
            }

            var marketInfos = [MarketInfoRecord]()

            for rate in rates.values {
                let coinCode = rate.coinCode == UniswapSubgraphProvider.WETHTokenCode ? UniswapSubgraphProvider.ETHCoinCode : rate.coinCode
                let latestPrice = rate.latestPriceInETH * ethPrice
                let dayOpenUSDPrice = rate.dayStartPriceInUSD
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

    private func marketBlockHeights(fetchDiffPeriod: TimePeriod) -> Single<(blockHeight24: Int?, fetchBlockHeight: Int?)> {
        let currentTimestamp = Date().timeIntervalSince1970
        var periods = [TimePeriod: TimeInterval]()

        periods[.hour24] = currentTimestamp - TimePeriod.hour24.seconds
        periods[fetchDiffPeriod] = currentTimestamp - fetchDiffPeriod.seconds

        return ethBlocksGraphProvider
            .blockHeight(data: periods)
            .map { blockHeightForPeriods in
                (blockHeight24: blockHeightForPeriods[TimePeriod.hour24], fetchBlockHeight: blockHeightForPeriods[fetchDiffPeriod])
            }
    }

    private func coinMarkets(currencyCode: String, tokens: UniswapGraphTokensResponse, tokens24: UniswapGraphTokensResponse, tokensPeriod: UniswapGraphTokensResponse? = nil) -> [CoinMarket] {
        tokens.tokens.map { token in
            let latestRate = token.latestRateInETH * tokens.ethPriceInUSD

            let token24 = tokens24.tokens.first { $0.tokenAddress == token.tokenAddress }

            let rateOpenDay = token24.map { $0.latestRateInETH * tokens24.ethPriceInUSD } ?? 0
            let volume24 = token24.map { token.volumeInUSD - $0.volumeInUSD } ?? 0
            let token24Rate = token24.map { $0.latestRateInETH * tokens24.ethPriceInUSD } ?? 0
            let rateDiff24 = token24Rate == 0 ? 0 : 100 * (latestRate - token24Rate) / token24Rate

            let tokenPeriod = tokensPeriod?.tokens.first { $0.tokenAddress == token.tokenAddress } ?? token24
            let tokenPeriodRate = tokenPeriod.map { $0.latestRateInETH * tokens24.ethPriceInUSD } ?? 0
            let rateDiffPeriod = tokenPeriodRate == 0 ? 0 : (100 * (latestRate - tokenPeriodRate) / tokenPeriodRate)

            let marketInfoRecord = MarketInfoRecord(
                    coinCode: token.coinCode,
                    currencyCode: currencyCode,
                    rate: latestRate,
                    openDay: rateOpenDay,
                    diff: rateDiff24,
                    volume: volume24,
                    marketCap: 0,
                    supply: 0,
                    liquidity: latestRate * token.totalLiquidity,
                    rateDiffPeriod: rateDiffPeriod)

            let coin = XRatesKit.Coin(
                    code: token.coinCode,
                    title: token.coinTitle,
                    type: .erc20(address: token.tokenAddress))

            return CoinMarket(coin: coin, record: marketInfoRecord, expirationInterval: expirationInterval)
        }.sorted { $0.marketInfo.liquidity > $1.marketInfo.liquidity }
    }

    private func requestedCoinMarketsSingle(factory: @escaping (Int?) -> Single<UniswapGraphTokensResponse>, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[CoinMarket]> {
        Single.zip(
                marketBlockHeights(fetchDiffPeriod: fetchDiffPeriod),
                factory(nil)
        ).flatMap { [weak self] heights, topTokens in
            guard heights.fetchBlockHeight != heights.blockHeight24 else {
                return factory(heights.blockHeight24)
                    .map { [weak self] tokens24 in
                        self?.coinMarkets(currencyCode: currencyCode, tokens: topTokens, tokens24: tokens24) ?? []
                    }
            }

            return Single.zip(
                factory(heights.blockHeight24),
                factory(heights.fetchBlockHeight)
            ).map { [weak self] tokens24, tokensPeriod in
                self?.coinMarkets(currencyCode: currencyCode, tokens: topTokens, tokens24: tokens24, tokensPeriod: tokensPeriod) ?? []
            }
        }
    }

}

extension UniswapSubgraphProvider: ICoinMarketsProvider {

    public func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        let factory = { [weak self] (blockHeight: Int?) in
            self?.topTokensSingle(itemCount: itemCount, blockHeight: blockHeight) ?? Single.error(Self.ProviderError.badSelfAccess)
        }

        return requestedCoinMarketsSingle(factory: factory, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coins: [XRatesKit.Coin]) -> Single<[CoinMarket]> {
        let addresses = tokenAddresses(coins: coins)

        let factory = { [weak self] (blockHeight: Int?) in
            self?.coinMarketsSingle(tokenAddresses: addresses, blockHeight: blockHeight) ?? Single.error(Self.ProviderError.badSelfAccess)
        }

        return requestedCoinMarketsSingle(factory: factory, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod)
    }

}

extension UniswapSubgraphProvider {

    enum ProviderError: Error {
        case badSelfAccess
    }

}
