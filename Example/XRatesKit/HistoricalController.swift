import UIKit
import RxSwift
import SnapKit
import XRatesKit
import CoinKit

class HistoricalController: UIViewController {
    private let disposeBag = DisposeBag()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coinType: CoinType

    private let timestamp = Date().timeIntervalSince1970

    private let datePicker = UIDatePicker()
    private let rateLabel = UILabel()

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

        title = "Historical"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(onTapFetch))

        view.addSubview(datePicker)
        datePicker.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            maker.height.equalTo(200)
        }

        datePicker.datePickerMode = .dateAndTime
        datePicker.maximumDate = Date()
        datePicker.locale = Locale.current
        datePicker.addTarget(self, action: #selector(onDateChanged), for: .valueChanged)

        view.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.top.equalTo(datePicker.snp.bottom).offset(20)
        }

        rateLabel.numberOfLines = 0
        rateLabel.textAlignment = .center
        rateLabel.font = .systemFont(ofSize: 17, weight: .medium)

        showStoredRate()
    }

    @objc func onDateChanged() {
        showStoredRate()
    }

    @objc func onTapFetch() {
        rateLabel.text = "Fetching..."

        let timestamp = timestampWithoutSeconds(date: datePicker.date)

        xRatesKit.historicalRateSingle(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] value in
                    self?.show(rate: value, timestamp: timestamp)
                }, onError: { [weak self] error in
                    self?.rateLabel.text = "Fetch error: \(error)"
                })
                .disposed(by: disposeBag)
    }

    private func showStoredRate() {
        let timestamp = timestampWithoutSeconds(date: datePicker.date)
        let storedRate = xRatesKit.historicalRate(coinType: coinType, currencyCode: currencyCode, timestamp: timestamp)

        show(rate: storedRate, timestamp: timestamp)
    }

    private func show(rate: Decimal?, timestamp: TimeInterval) {
        let rateText = rate.flatMap { HistoricalController.rateFormatter.string(from: $0 as NSNumber) } ?? "not fetched yet"
        let dateText = HistoricalController.dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
        rateLabel.text = "Rate for \(dateText)\n\n\(rateText)"
    }

    private func timestampWithoutSeconds(date: Date) -> TimeInterval {
        floor(date.timeIntervalSince1970 / 60.0) * 60.0
    }

}

extension HistoricalController {

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
