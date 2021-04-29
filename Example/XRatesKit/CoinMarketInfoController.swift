import UIKit
import RxSwift
import SnapKit
import XRatesKit
import CoinKit

class CoinMarketInfoController: UIViewController {
    private let disposeBag = DisposeBag()

    private let wrapper = UIScrollView()
    private let coinMarketInfoLabel = UILabel()
    private let pointsLabel = UILabel()

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
            maker.top.leading.trailing.equalToSuperview()
        }
        coinMarketInfoLabel.font = .systemFont(ofSize: 14)
        coinMarketInfoLabel.textColor = .black
        coinMarketInfoLabel.numberOfLines = 0
        coinMarketInfoLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 30
        coinMarketInfoLabel.lineBreakMode = .byWordWrapping

        wrapper.addSubview(pointsLabel)
        pointsLabel.snp.makeConstraints { maker in
            maker.top.equalTo(coinMarketInfoLabel.snp.bottom).offset(50)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        pointsLabel.font = .systemFont(ofSize: 14)
        pointsLabel.textColor = .black
        pointsLabel.numberOfLines = 0
        pointsLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 30
        pointsLabel.lineBreakMode = .byWordWrapping

        xRatesKit.coinMarketInfoSingle(coinType: coinType, currencyCode: currencyCode, rateDiffTimePeriods: timePeriods, rateDiffCoinCodes: coinCodes)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] marketInfo in
                    self?.bind(marketInfo: marketInfo)
                })
                .disposed(by: disposeBag)

        xRatesKit.defiTvlPoints(coinType: coinType, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] points in
                    self?.bind(points: points)
                })
                .disposed(by: disposeBag)
    }

    private func bind(points: [DefiTvlPoint]) {
        pointsLabel.text = points.map { point in
            """
            currencyCode: \(point.currencyCode)
            timestamp: \(point.timestamp)
            tvl: \(point.tvl)
            """
        }.joined(separator: "\n\n")
    }

    private func bind(marketInfo: CoinMarketInfo) {
        var str = """
                  coinId: \(marketInfo.data.coinType.id)
                  currencyCode: \(marketInfo.currencyCode)
                  rate: \(marketInfo.rate ?? -1)
                  rateHigh24h: \(marketInfo.rateHigh24h ?? -1)
                  rateLow24h: \(marketInfo.rateLow24h ?? -1)
                  totalSupply: \(marketInfo.totalSupply ?? -1)
                  circulatingSupply: \(marketInfo.circulatingSupply ?? -1)
                  volume24h: \(marketInfo.volume24h ?? -1)
                  marketCap: \(marketInfo.marketCap ?? -1)
                  marketCapDiff24h: \(marketInfo.marketCapDiff24h ?? -1)
                  dilutedMarketCap: \(marketInfo.dilutedMarketCap ?? -1)
                  defiTvl: \(marketInfo.defiTvlInfo?.tvl ?? -1)
                  tvlRank: \(marketInfo.defiTvlInfo?.tvlRank ?? -1)

                  description: \(marketInfo.meta.description)

                  == Categories ==
                  \(marketInfo.meta.categories.joined(separator: "\n"))

                  == Funds ==
                  \(marketInfo.meta.fundCategories.map{ c in "==== \(c.name)\n\(c.funds.map { "\($0.name) - \($0.url)" }.joined(separator: "\n"))" }.joined(separator: "\n\n"))

                  == Platforms ==
                  \(marketInfo.meta.platforms.map{ (key, value) in "\(key.rawValue): \(value)" }.joined(separator: "\n"))

                  == Markets ==
                  \(marketInfo.tickers.map{ ticker in "\(ticker.marketName): \(ticker.base)/\(ticker.target) (rate: \(ticker.rate); volume: \(ticker.volume))\n\(ticker.marketImageUrl ?? "no image")" }.joined(separator: "\n\n"))

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
