import UIKit
import RxSwift
import SnapKit
import XRatesKit
import CoinKit

class CoinMarketInfoController: UIViewController {
    private let disposeBag = DisposeBag()

    private let wrapper = UIScrollView()
    private let coinMarketInfoLabel = UILabel()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coinType: CoinType
    private let timePeriods = [TimePeriod.day7, TimePeriod.day30]
    private let coinCodes = ["USD", "BTC", "ETH"]

    init(xRatesKit: XRatesKit, currencyCode: String, coinType: CoinType) {
        self.xRatesKit = xRatesKit
        self.currencyCode = currencyCode
        self.coinType = coinType

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Coin Market Info"

        view.backgroundColor = .white

        view.addSubview(wrapper)
        wrapper.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(20)
        }

        wrapper.addSubview(coinMarketInfoLabel)
        coinMarketInfoLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        coinMarketInfoLabel.font = .systemFont(ofSize: 14)
        coinMarketInfoLabel.textColor = .black
        coinMarketInfoLabel.numberOfLines = 0
        coinMarketInfoLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 30
        coinMarketInfoLabel.lineBreakMode = .byWordWrapping

        onTapRefresh()
    }

    @objc func onTapRefresh() {
        xRatesKit.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: timePeriods, rateDiffCoinCodes: coinCodes)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] marketInfo in
                    self?.bind(marketInfo: marketInfo)
                })
                .disposed(by: disposeBag)
    }

    private func bind(marketInfo: CoinMarketInfo) {
        var str = """
                  coinId: \(marketInfo.data.coinType.id)
                  currencyCode: \(marketInfo.currencyCode)
                  rate: \(marketInfo.rate)
                  rateHigh24h: \(marketInfo.rateHigh24h)
                  rateLow24h: \(marketInfo.rateLow24h)
                  totalSupply: \(marketInfo.totalSupply)
                  circulatingSupply: \(marketInfo.circulatingSupply)
                  volume24h: \(marketInfo.volume24h)
                  marketCap: \(marketInfo.marketCap)
                  marketCapDiff24h: \(marketInfo.marketCapDiff24h)

                  description: \(marketInfo.meta.description)
                  categories: \(marketInfo.meta.categories.joined(separator: ", "))

                  == Categories ==
                  \(marketInfo.meta.categories.joined(separator: "\n"))

                  == Platforms ==
                  \(marketInfo.meta.platforms.map{ (key, value) in "\(key.rawValue): \(value)" }.joined(separator: "\n"))

                  == Links ==
                  \(marketInfo.meta.links.map { (key, value) in "\(key.rawValue.uppercased()): \(value)" }.joined(separator: "\n"))

                  == Rate Diffs ==
                  """

        for (timePeriod, rateDiff) in marketInfo.rateDiffs {
            str += "\n\(timePeriod.rawValue)\n"

            for (coinCode, value) in rateDiff {
                str += "\(coinCode): \(value)\n"
            }
        }

        coinMarketInfoLabel.text = str
    }

}
