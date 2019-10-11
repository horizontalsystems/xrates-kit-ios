import UIKit
import XRatesKit
import RxSwift

class ViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let coinCodes = ["BTC", "ETH", "BNB"]//, "GNT", "GUSD", "GTO", "HOT", "HT", "IDEX", "IDXM", "IQ", "KCS", "KNC"]
    private let baseCurrencyCode = "USD"

    @IBOutlet weak var textView: UITextView?

    private let dateFormatter = DateFormatter()
    private let xRatesKit = XRatesKit.instance(currencyCode: "USD", minLogLevel: .verbose)

    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, hh:mm:ss")

        xRatesKit.update(coinCodes: coinCodes)
        for coinCode in coinCodes {
            xRatesKit.latestRateObservable(coinCode: coinCode, currencyCode: baseCurrencyCode)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] rate in
                        self?.fetchNew(rate: rate)
                    })
                    .disposed(by: disposeBag)
        }

        initialTextView()
    }

    @IBAction func refresh() {
        xRatesKit.refresh()
        printChartData()

        xRatesKit.historicalRate(coinCode: "BTC", currencyCode: "RUB", date: Date(timeIntervalSinceNow: 0))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { decimal in
                let oldText = self.textView?.text ?? ""
                self.textView?.text = oldText + "\(decimal)\n"
        }, onError: { error in
            print("historical error: \(error) \n")
        }).disposed(by: disposeBag)
    }

    private func printChartData() {
        let chartData = xRatesKit.chartStats(coinCode: "BTC", currencyCode: "USD", chartType: .day)

        print("db data: \n \(chartData.map { "\(Date(timeIntervalSince1970: $0.timestamp)) - \(($0.value))" }.joined(separator: "\n"))")
        xRatesKit.chartStatsObservable(coinCode: "BTC", currencyCode: "USD", chartType: .day)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { chartData in
                    print("subject data: \n \(chartData.map { "\(Date(timeIntervalSince1970: $0.timestamp)) - \(($0.value))" }.joined(separator: "\n"))")
                })
                .disposed(by: disposeBag)
    }

    private func fetchNew(rate: RateInfo) {
        let oldText = textView?.text ?? ""
        textView?.text = oldText + format(title: dateFormatter.string(from: Date()) + " : ", rate: rate)
    }

    private func initialTextView() {
        textView?.text = "Initial State: \n"
        for coinCode in coinCodes {
            if let rate = xRatesKit.latestRate(coinCode: coinCode, currencyCode: baseCurrencyCode) {
                fetchNew(rate: rate)
            }
        }
        textView?.text += "======================\n"
    }

    private func format(title: String, rate: RateInfo?) -> String {
        guard let rate = rate else {
            return "No rate!"
        }
        return "[\(title)]\n" +
                "Date: \(dateFormatter.string(from: rate.date))\n" +
                "Value: \(rate.value)\n" +
                "CoinCode: \(rate.coinCode), currencyCode: \(rate.currencyCode)\n\n"
    }

}
