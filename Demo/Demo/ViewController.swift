import UIKit
import RxSwift
import SnapKit
import XRatesKit

class ViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private var chartDisposeBag = DisposeBag()

    private let coinCodes = ["BTC", "ETH", "BNB", "AURA"]//, "GNT", "GUSD", "GTO", "HOT", "HT", "IDEX", "IDXM", "IQ", "KCS", "KNC"]
    private let currencyCode = "USD"

    private var latestRates = [String: Rate]()
    private var chartInfo: ChartInfo?
    private var chartOn = false

    private let textView = UITextView()

    private let dateFormatter = DateFormatter()
    private let xRatesKit: XRatesKit

    init() {
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, hh:mm:ss")

        xRatesKit = XRatesKit.instance(currencyCode: currencyCode, minLogLevel: .verbose)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Fetch Historical", style: .plain, target: self, action: #selector(onTapHistorical))

        textView.font = .systemFont(ofSize: 14)
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
        }

        let refreshButton = UIButton()
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.setTitleColor(.darkGray, for: .normal)
        refreshButton.addTarget(self, action: #selector(onTapRefresh), for: .touchUpInside)

        view.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.top.equalTo(textView.snp.bottom)
            maker.height.equalTo(100)
        }

        syncChartButton()
        fillInitialData()

        xRatesKit.set(coinCodes: coinCodes)

        for coinCode in coinCodes {
            xRatesKit.latestRateObservable(coinCode: coinCode, currencyCode: currencyCode)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] rate in
                        self?.latestRates[coinCode] = rate
                        self?.updateTextView()
                    })
                    .disposed(by: disposeBag)
        }
    }

    @objc func onTapRefresh() {
        xRatesKit.refresh()
    }

    @objc func onTapHistorical() {
        xRatesKit.historicalRate(coinCode: "BTC", currencyCode: "USD", date: Date(timeIntervalSinceNow: 0))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { value in
                    print("Did fetch Historical Rate: \(value)")
                }, onError: { error in
                    print("Historical Rate fetch error: \(error.localizedDescription)")
                })
                .disposed(by: disposeBag)
    }

    @objc func onTapChart() {
        if chartOn {
            chartOn = false
            onChartOff()
        } else {
            chartOn = true
            onChartOn()
        }

        syncChartButton()
        updateTextView()
    }

    private func syncChartButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: chartOn ? "Chart ON" : "Chart OFF", style: .plain, target: self, action: #selector(onTapChart))
    }

    private func onChartOn() {
        let coinCode = "BTC"
        let currencyCode = "USD"
        let chartType: ChartType = .day

        chartInfo = xRatesKit.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)

        xRatesKit.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chartInfo in
                    self?.chartInfo = chartInfo
                    self?.updateTextView()
                })
                .disposed(by: chartDisposeBag)
    }

    private func onChartOff() {
        chartInfo = nil
        chartDisposeBag = DisposeBag()
    }

    private func fillInitialData() {
        for coinCode in coinCodes {
            latestRates[coinCode] = xRatesKit.latestRate(coinCode: coinCode, currencyCode: currencyCode)
        }

        updateTextView()
    }

    private func updateTextView() {
        var text = ""

        for coinCode in coinCodes {
            text += "\(coinCode): "

            if let rate = latestRates[coinCode] {
                text += "\(rate.expired ? "⛔" : "✅")\n"
                text += "   • \(rate.value)\n"
                text += "   • \(dateFormatter.string(from: rate.date))\n"
            } else {
                text += "n/a\n"
            }

            text += "\n"
        }

        text += "\n"

        if let chartInfo = chartInfo {
            text += "Chart Info:\n"
            text += "Diff: \(chartInfo.diff.map { "\($0)" } ?? "n/a")\n"
            text += "Start Date: \(dateFormatter.string(from: chartInfo.startDate))\n"
            text += "End Date: \(dateFormatter.string(from: chartInfo.endDate))\n"

            for point in chartInfo.points {
                let formattedDate = dateFormatter.string(from: point.date)
                text += "   \(formattedDate): \(point.value)\n"
            }
        }

        textView.text = text
    }

}
