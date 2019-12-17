import UIKit
import RxSwift
import SnapKit
import XRatesKit

class MarketInfoController: UIViewController {
    private let disposeBag = DisposeBag()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coinCodes: [String]

    private let textView = UITextView()

    private var marketInfos = [String: MarketInfo]()
    private let dateFormatter = DateFormatter()

    init(xRatesKit: XRatesKit, currencyCode: String, coinCodes: [String]) {
        self.xRatesKit = xRatesKit
        self.currencyCode = currencyCode
        self.coinCodes = coinCodes

        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, hh:mm:ss")

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Market Info"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(onTapRefresh))

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        textView.font = .systemFont(ofSize: 12)
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)

        fillInitialData()

        xRatesKit.marketInfosObservable(currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.marketInfos = marketInfos
                    self?.updateTextView()
                })
                .disposed(by: disposeBag)
    }

    @objc func onTapRefresh() {
        xRatesKit.refresh()
    }

    private func fillInitialData() {
        for coinCode in coinCodes {
            marketInfos[coinCode] = xRatesKit.marketInfo(coinCode: coinCode, currencyCode: currencyCode)
        }

        updateTextView()
    }

    private func updateTextView() {
        var text = ""

        for coinCode in coinCodes {
            text += "\(coinCode): "

            if let marketInfo = marketInfos[coinCode] {
                text += "\(marketInfo.expired ? "⛔" : "✅")\n"
                text += "   • \(format(timestamp: marketInfo.timestamp))\n"
                text += "   • \(marketInfo.rate)\n"
                text += "   • \(marketInfo.diff)\n"
                text += "   • Volume: \(marketInfo.volume)\n"
                text += "   • Market Cap: \(marketInfo.marketCap)\n"
                text += "   • Supply: \(marketInfo.supply)\n"
            } else {
                text += "n/a\n"
            }

            text += "\n"
        }

        textView.text = text
    }

    private func format(timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return dateFormatter.string(from: date)
    }

}
