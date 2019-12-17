import UIKit
import RxSwift
import SnapKit
import XRatesKit

class ChartController: UIViewController {
    private let disposeBag = DisposeBag()
    private var chartDisposeBag = DisposeBag()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coinCode: String

    private let chartType: ChartType = .day

    private var chartData: ChartData?
    private var chartOn = false

    private let textView = UITextView()

    private let dateFormatter = DateFormatter()

    init(xRatesKit: XRatesKit, currencyCode: String, coinCode: String) {
        self.xRatesKit = xRatesKit
        self.currencyCode = currencyCode
        self.coinCode = coinCode

        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, hh:mm:ss")

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chart"

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        textView.font = .systemFont(ofSize: 10)
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)

        syncChartButton()
        fillInitialData()
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
    }

    private func syncChartButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: chartOn ? .stop : .play, target: self, action: #selector(onTapChart))
    }

    private func onChartOn() {
        xRatesKit.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chartInfo in
                    self?.chartData = .data(chartInfo: chartInfo)
                    self?.updateTextView()
                }, onError: { error in
                    self.chartData = .error(error: error)
                    self.updateTextView()
                })
                .disposed(by: chartDisposeBag)

//        additionalSubscribe(coinCode: "BNT", currencyCode: "USD")
//        additionalSubscribe(coinCode: "ETH", currencyCode: "USD")
//        additionalSubscribe(coinCode: "EOS", currencyCode: "USD")
//        additionalSubscribe(coinCode: "ZRX", currencyCode: "USD")
    }

//    private func additionalSubscribe(coinCode: String, currencyCode: String) {
//        _ = xRatesKit.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: .day)
//
//        xRatesKit.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: .day)
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
//                .observeOn(MainScheduler.instance)
//                .subscribe()
//                .disposed(by: chartDisposeBag)
//    }

    private func onChartOff() {
        chartDisposeBag = DisposeBag()
    }

    private func fillInitialData() {
        if let chartInfo = xRatesKit.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType) {
            chartData = .data(chartInfo: chartInfo)
            updateTextView()
        }
    }

    private func updateTextView() {
        var text = ""

        if let chartData = chartData {
            switch chartData {
            case .data(let chartInfo):
//                text += "Start Date: \(format(timestamp: chartInfo.startTimestamp))\n"
//                text += "End Date: \(format(timestamp: chartInfo.endTimestamp))\n"

//                if let point = chartInfo.points.first {
//                    text += "   \(format(timestamp: point.timestamp)): \(point.value)\n"
//                }
//                if let point = chartInfo.points.last {
//                    text += "   \(format(timestamp: point.timestamp)): \(point.value)\n"
//                }

                for point in chartInfo.points {
                    text += "\(format(timestamp: point.timestamp)): \(point.value)\n"
                }
            case .error(let error):
                text += "Error: \(error)\n"
            }

        }

        textView.text = text
    }

    private func format(timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return dateFormatter.string(from: date)
    }

}

enum ChartData {
    case data(chartInfo: ChartInfo)
    case error(error: Error)
}
