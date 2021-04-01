import UIKit
import RxSwift
import SnapKit
import XRatesKit
import CoinKit

class LatestRatesController: UITableViewController {
    private let disposeBag = DisposeBag()

    private let xRatesKit: XRatesKit
    private let currencyCode: String
    private let coins: [Coin]

    private var latestRates = [CoinType: LatestRate]()

    init(xRatesKit: XRatesKit, currencyCode: String, coins: [Coin]) {
        self.xRatesKit = xRatesKit
        self.currencyCode = currencyCode
        self.coins = coins

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Market Info"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(onTapRefresh))

        tableView.register(MarketInfoCell.self, forCellReuseIdentifier: String(describing: MarketInfoCell.self))
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()

        fillInitialData()

        xRatesKit.latestRatesObservable(coinTypes: coins.map { $0.type }, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfos in
                    self?.latestRates = marketInfos
                    self?.tableView.reloadData()
                })
                .disposed(by: disposeBag)
    }

    @objc func onTapRefresh() {
        xRatesKit.refresh(currencyCode: currencyCode)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        coins.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MarketInfoCell.self)) {
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? MarketInfoCell else {
            return
        }

        let coin = coins[indexPath.row]

        cell.bind(coinCode: coin.code, latestRate: latestRates[coin.type])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let coin = coins[indexPath.row]
        let view = CoinMarketInfoController(xRatesKit: xRatesKit, currencyCode: currencyCode, coinType: coin.type)
        navigationController?.present(view, animated: true)
    }

    private func fillInitialData() {
        for coin in coins {
            latestRates[coin.type] = xRatesKit.latestRate(coinType: coin.type, currencyCode: currencyCode)
        }
    }

}
