import UIKit
import RxSwift
import SnapKit
import Chart
import XRatesKit

class ChartController: UIViewController {
    private let disposeBag = DisposeBag()
    private var chartDisposeBag = DisposeBag()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coinCode: String

    private let chartType: ChartType = .day
    private var chartUpdatesOn = false

    private let rateLabel = UILabel()
    private var chartView: ChartView?

    init(xRatesKit: XRatesKit, currencyCode: String, coinCode: String) {
        self.xRatesKit = xRatesKit
        self.currencyCode = currencyCode
        self.coinCode = coinCode

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chart"

        let configuration = ChartConfiguration()
        let chartView = ChartView(configuration: configuration, gridIntervalType: .day(2), indicatorDelegate: self)

        view.addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.height.equalTo(200)
        }

        chartView.backgroundColor = .black
        self.chartView = chartView

        view.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.top.equalTo(chartView.snp.bottom).offset(20)
            maker.leading.trailing.equalToSuperview().inset(20)
        }

        rateLabel.numberOfLines = 0
        rateLabel.textAlignment = .center
        rateLabel.font = .systemFont(ofSize: 14, weight: .medium)

        syncChartButton()
        fillInitialData()
    }

    @objc func onTapChart() {
        if chartUpdatesOn {
            chartUpdatesOn = false
            onChartOff()
        } else {
            chartUpdatesOn = true
            onChartOn()
        }

        syncChartButton()
    }

    private func syncChartButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: chartUpdatesOn ? .stop : .play, target: self, action: #selector(onTapChart))
    }

    private func onChartOn() {
        xRatesKit.chartInfoObservable(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chartInfo in
                    self?.handle(chartInfo: chartInfo)
                }, onError: { [weak self] error in
                    self?.rateLabel.text = "Subscription error: \(error)"
                })
                .disposed(by: chartDisposeBag)
    }

    private func onChartOff() {
        chartDisposeBag = DisposeBag()
    }

    private func fillInitialData() {
        if let chartInfo = xRatesKit.chartInfo(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType) {
            handle(chartInfo: chartInfo)
        }
    }

    private func handle(chartInfo: ChartInfo) {
        let chartPoints = chartInfo.points.map { Chart.ChartPoint(timestamp: $0.timestamp, value: $0.value) }
        chartView?.set(gridIntervalType: .hour(6), data: chartPoints, start: chartInfo.startTimestamp, end: chartInfo.endTimestamp, animated: true)
    }

}

extension ChartController: IChartIndicatorDelegate {

    public func didTap(chartPoint: Chart.ChartPoint) {
        let rateText = ChartController.rateFormatter.string(from: chartPoint.value as NSNumber) ?? "n/a"
        let dateText = ChartController.dateFormatter.string(from: Date(timeIntervalSince1970: chartPoint.timestamp))
        rateLabel.text = "\(dateText)\n\n\(rateText)"
    }

    public func didFinishTap() {
        rateLabel.text = nil
    }

}

extension ChartController {

    static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d, hh:mm:ss"
        return formatter
    }()

}
