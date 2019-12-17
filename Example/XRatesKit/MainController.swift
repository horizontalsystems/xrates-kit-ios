import UIKit
import XRatesKit

class MainController: UITabBarController {
    private let currencyCode = "USD"

    private let marketInfoCoinCodes = ["BTC", "ETH", "BCH", "DASH", "BNB", "EOS"]
    private let historicalCoinCode = "BTC"
    private let chartCoinCode = "BTC"

    init() {
        super.init(nibName: nil, bundle: nil)

        let xRatesKit = XRatesKit.instance(currencyCode: currencyCode, minLogLevel: .verbose)
        xRatesKit.set(coinCodes: marketInfoCoinCodes)

        let marketInfoController = MarketInfoController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinCodes: marketInfoCoinCodes)
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
