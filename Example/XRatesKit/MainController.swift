import UIKit
import XRatesKit
import CoinKit

class MainController: UITabBarController {
    private let currencyCode = "USD"

    private let marketInfoCoins = [
        Coin(title: "Bitcoin", code: "BTC", decimal: 0, type: .bitcoin),
        Coin(title: "Ethereum", code: "ETH", decimal: 0, type: .ethereum),
        Coin(title: "Bitcoin Cash", code: "BCH", decimal: 0, type: .bitcoinCash),
        Coin(title: "Dash", code: "DASH", decimal: 0, type: .dash),
        Coin(title: "Binance", code: "BNB", decimal: 0, type: .bep2(symbol: "BNB")),
        Coin(title: "Binance Smart Chain", code: "BNB", decimal: 0, type: .binanceSmartChain),
        Coin(title: "UNI Token", code: "Uni", decimal: 0, type: .erc20(address: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984")),
        Coin(title: "aDAI Token", code: "ADAI", decimal: 0, type: .erc20(address: "0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d")),
        Coin(title: "Pundi X", code: "NPXS", decimal: 0, type: .erc20(address: "0xa15c7ebe1f07caf6bff097d8a589fb8ac49ae5b3"))
    ]
    private let historicalCoinType = CoinType.bitcoin
    private let chartCoinType = CoinType.bitcoin

    init() {
        super.init(nibName: nil, bundle: nil)

        let xRatesKit = XRatesKit.instance(
                currencyCode: currencyCode,
                uniswapSubgraphUrl: "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2",
                providerCoinsUrl: "https://raw.githubusercontent.com/horizontalsystems/cryptocurrencies/master/provider.coins.json",
                coinsUrl: "https://raw.githubusercontent.com/horizontalsystems/cryptocurrencies/master/coins.json",
                minLogLevel: .error
        )

        let topMarketInfoController = TopMarketController(xRatesKit: xRatesKit, storage: UserDefaultsStorage(), currencyCode: currencyCode)
        topMarketInfoController.tabBarItem = UITabBarItem(title: "Top Markets", image: UIImage(systemName: "dollarsign.circle"), tag: 0)

        let latestRateController = LatestRatesController(xRatesKit: xRatesKit, currencyCode: currencyCode, coins: marketInfoCoins)
        latestRateController.tabBarItem = UITabBarItem(title: "Latest Rate", image: UIImage(systemName: "dollarsign.circle"), tag: 0)

        let historicalController = HistoricalController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinType: historicalCoinType)
        historicalController.tabBarItem = UITabBarItem(title: "Historical", image: UIImage(systemName: "calendar"), tag: 1)

        let chartController = ChartController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinType: chartCoinType)
        chartController.tabBarItem = UITabBarItem(title: "Chart", image: UIImage(systemName: "chart.bar"), tag: 2)

        let coinSearchController = CoinSearchController(xRatesKit: xRatesKit)
        coinSearchController.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 0)

        viewControllers = [
            UINavigationController(rootViewController: topMarketInfoController),
            UINavigationController(rootViewController: latestRateController),
            UINavigationController(rootViewController: historicalController),
            UINavigationController(rootViewController: chartController),
            UINavigationController(rootViewController: coinSearchController)
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
