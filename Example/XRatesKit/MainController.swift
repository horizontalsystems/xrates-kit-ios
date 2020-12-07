import UIKit
import XRatesKit

class MainController: UITabBarController {
    private let currencyCode = "USD"

    private let marketInfoCoins = [
        XRatesKit.Coin(code: "BTC", title: "Bitcoin", type: .bitcoin),
        XRatesKit.Coin(code: "ETH", title: "Ethereum", type: .ethereum),
        XRatesKit.Coin(code: "BCH", title: "Bitcoin Cash", type: .bitcoinCash),
        XRatesKit.Coin(code: "DASH", title: "Dash", type: .dash),
        XRatesKit.Coin(code: "BNB", title: "Binance", type: .binance),
        XRatesKit.Coin(code: "EOS", title: "EOS", type: .eos),
        XRatesKit.Coin(code: "Uni", title: "UNI Token", type: .erc20(address: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984")),
        XRatesKit.Coin(code: "ADAI", title: "aDAI Token", type: .erc20(address: "0xfc1e690f61efd961294b3e1ce3313fbd8aa4f85d"))
    ]
    private let historicalCoinCode = "BTC"
    private let chartCoinCode = "BTC"

    init() {
        super.init(nibName: nil, bundle: nil)

        let xRatesKit = XRatesKit.instance(currencyCode: currencyCode, uniswapSubgraphUrl: "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2", minLogLevel: .verbose)
        xRatesKit.set(coins: marketInfoCoins)

        let marketInfoController = MarketInfoController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinCodes: marketInfoCoins.map { $0.code })
        marketInfoController.tabBarItem = UITabBarItem(title: "Market Info", image: UIImage(systemName: "dollarsign.circle"), tag: 0)

        let historicalController = HistoricalController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinCode: historicalCoinCode)
        historicalController.tabBarItem = UITabBarItem(title: "Historical", image: UIImage(systemName: "calendar"), tag: 1)

        let chartController = ChartController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinCode: chartCoinCode)
        chartController.tabBarItem = UITabBarItem(title: "Chart", image: UIImage(systemName: "chart.bar"), tag: 2)

        viewControllers = [
            UINavigationController(rootViewController: marketInfoController),
            UINavigationController(rootViewController: historicalController),
            UINavigationController(rootViewController: chartController)
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
