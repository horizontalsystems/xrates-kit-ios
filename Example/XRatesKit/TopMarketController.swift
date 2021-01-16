import UIKit
import RxSwift
import SnapKit
import Chart
import XRatesKit

class TopMarketController: UIViewController {
    private let disposeBag = DisposeBag()
    private var globalMarketDisposable: Disposable?
    private var topMarketsDisposable: Disposable?

    private let xRatesKit: XRatesKit
    private let storage: UserDefaultsStorage
    private let currencyCode: String

    private var period: TimePeriod = .hour24

    private let globalWrapper = UIView()
    private let globalVolumeLabel = UILabel()
    private let globalVolumeDiffLabel = UILabel()
    private let globalDominanceLabel = UILabel()
    private let globalDominanceDiffLabel = UILabel()

    private let segmentedView = UISegmentedControl(items: ["Top100", "Defi", "Favorites"])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerView = NewsHeaderView()

    private var topMarkets = [CoinMarket]()
    private var globalMarketInfo: GlobalCoinMarket?

    private var favoriteCoins = [XRatesKit.Coin]()

    init(xRatesKit: XRatesKit, storage: UserDefaultsStorage, currencyCode: String) {
        self.xRatesKit = xRatesKit
        self.storage = storage
        self.currencyCode = currencyCode

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Top Market"

        view.addSubview(globalWrapper)
        globalWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.height.equalTo(64)
        }

        globalWrapper.addSubview(globalVolumeLabel)
        globalVolumeLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.height.equalTo(32)
        }

        globalVolumeLabel.font = .systemFont(ofSize: 14)
        globalVolumeLabel.textColor = .black

        globalWrapper.addSubview(globalVolumeDiffLabel)
        globalVolumeDiffLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalTo(globalVolumeLabel.snp.trailing).offset(8)
            maker.trailing.equalToSuperview()
            maker.height.equalTo(32)
        }

        globalVolumeDiffLabel.font = .systemFont(ofSize: 14)
        globalVolumeDiffLabel.textColor = .black

        globalWrapper.addSubview(globalDominanceLabel)
        globalDominanceLabel.snp.makeConstraints { maker in
            maker.top.equalTo(globalVolumeLabel.snp.bottom).offset(4)
            maker.leading.equalToSuperview()
            maker.height.equalTo(28)
        }

        globalDominanceLabel.font = .systemFont(ofSize: 14)
        globalDominanceLabel.textColor = .black

        globalWrapper.addSubview(globalDominanceDiffLabel)
        globalDominanceDiffLabel.snp.makeConstraints { maker in
            maker.top.equalTo(globalVolumeLabel.snp.bottom).offset(4)
            maker.leading.equalTo(globalVolumeLabel.snp.trailing).offset(8)
            maker.trailing.equalToSuperview()
            maker.height.equalTo(28)
        }

        globalDominanceDiffLabel.font = .systemFont(ofSize: 14)
        globalDominanceDiffLabel.textColor = .black

        view.addSubview(segmentedView)
        segmentedView.snp.makeConstraints { maker in
            maker.top.equalTo(globalWrapper.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.height.equalTo(32)
        }

        segmentedView.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedView.selectedSegmentIndex = 1

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(segmentedView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }

        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 30)
        tableView.tableHeaderView = headerView
        tableView.register(TopMarketCell.self, forCellReuseIdentifier: String(describing: TopMarketCell.self))
        tableView.separatorInset = .zero
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reloadGlobalMarketInfo()
        reloadTopMarkets()
    }

    private func reloadGlobalMarketInfo() {
        globalMarketDisposable?.dispose()

        globalMarketDisposable = xRatesKit.globalMarketInfoSingle(currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] globalInfo in
                    self?.set(globalInfo: globalInfo)
                }, onError: { [weak self] error in
                    self?.set(globalInfo: nil, error: error)
                })

        globalMarketDisposable?.disposed(by: disposeBag)
    }

    private func reloadTopMarkets() {
        topMarketsDisposable?.dispose()

        headerView.bind(title: "Loading...")

        topMarkets = []
        tableView.reloadData()

        let single: Single<[CoinMarket]>

        switch segmentedView.selectedSegmentIndex {
        case 0: single = xRatesKit.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: period, itemsCount: 200)
        case 1: single = xRatesKit.topDefiMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: period, itemsCount: 200)
        default: single = xRatesKit.favorites(currencyCode: currencyCode, fetchDiffPeriod: period, coins: favoriteCoins)
        }

        topMarketsDisposable = single
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] topMarkets in
                    self?.set(topMarkets: topMarkets)
                }, onError: { [weak self] error in
                    self?.set(topMarkets: nil, error: error)
                })

        topMarketsDisposable?.disposed(by: disposeBag)
    }

    @objc private func segmentChanged() {
        reloadTopMarkets()
    }

    private func string(from value: Decimal, fractionDigits: Int = 2) -> String {
        Self.rateFormatter.maximumFractionDigits = fractionDigits
        return Self.rateFormatter.string(from: value as NSNumber) ?? "N/A"
    }

    private func set(globalInfo: GlobalCoinMarket?, error: Error? = nil) {
        globalMarketInfo = globalInfo

        guard let globalInfo = globalInfo else {
            globalVolumeLabel.text = nil
            globalVolumeDiffLabel.text = nil
            globalDominanceLabel.text = nil
            globalDominanceDiffLabel.text = nil

            return
        }

        globalVolumeLabel.text = "Vol: \(string(from: globalInfo.volume24h))"
        globalVolumeDiffLabel.text = "VolDiff: \(string(from: globalInfo.volume24hDiff24h))"
        globalDominanceLabel.text = "Dom: \(string(from: globalInfo.btcDominance))"
        globalDominanceDiffLabel.text = "DomDiff: \(string(from: globalInfo.btcDominanceDiff24h))"
    }

    private func set(topMarkets: [CoinMarket]?, error: Error? = nil) {
        self.topMarkets = topMarkets ?? []
        tableView.reloadData()
        headerView.bind(title: error != nil ? (error?.localizedDescription ?? "Failed") : "Success")
    }

    private func toggle(coin: XRatesKit.Coin) {
        if let index = favoriteCoins.firstIndex(where: { $0.code == coin.code }) {
            favoriteCoins.remove(at: index)
        } else {
            favoriteCoins.append(coin)
        }
        tableView.reloadData()
    }

}

extension TopMarketController {

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

extension TopMarketController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        topMarkets.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TopMarketCell.self)) {
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TopMarketCell, topMarkets.count > indexPath.row else {
            return
        }

        let topMarket = topMarkets[indexPath.row]
        let favorite = favoriteCoins.contains { coin in topMarket.coin.code == coin.code }
        cell.bind(topMarket: topMarket, favorite: favorite) { [weak self] in
            self?.toggle(coin: topMarket.coin)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }

}
