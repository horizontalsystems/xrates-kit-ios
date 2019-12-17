import UIKit
import RxSwift
import SnapKit
import XRatesKit

class HistoricalController: UIViewController {
    private let disposeBag = DisposeBag()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coinCode: String

    private let timestamp = Date().timeIntervalSince1970

    private let textView = UITextView()

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

        title = "Historical"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(onTapHistorical))

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        textView.font = .systemFont(ofSize: 12)
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
    }

    @objc func onTapHistorical() {
        updateTextView(text: "Fetching...")

        xRatesKit.historicalRate(coinCode: coinCode, currencyCode: currencyCode, timestamp: timestamp)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] value in
                    self?.updateTextView(text: "Did fetch Historical Rate: \(value)")
                }, onError: { [weak self] error in
                    self?.updateTextView(text: "Historical Rate fetch error: \(error.localizedDescription)")
                })
                .disposed(by: disposeBag)
    }

    private func updateTextView(text: String) {
        textView.text = text
    }

}
