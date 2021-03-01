import UIKit
import RxSwift
import SnapKit
import XRatesKit
import CoinKit

class CoinSearchController: UIViewController {
    private let disposeBag = DisposeBag()

    private let searchBar = UISearchBar()
    private let searchResults = UILabel()

    private let xRatesKit: XRatesKit

    init(xRatesKit: XRatesKit) {
        self.xRatesKit = xRatesKit

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search"

        view.backgroundColor = .white

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.top.equalToSuperview().offset(120)
            maker.height.equalTo(40)
        }

        searchBar.delegate = self

        view.addSubview(searchResults)
        searchResults.snp.makeConstraints { maker in
            maker.leading.equalTo(searchBar)
            maker.top.equalTo(searchBar.snp.bottom).offset(20)
        }
        searchResults.font = .systemFont(ofSize: 14)
        searchResults.textColor = .black
        searchResults.numberOfLines = 0
        searchResults.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 30
        searchResults.lineBreakMode = .byWordWrapping
    }
}

extension CoinSearchController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let coins = xRatesKit.search(text: searchText)
        searchResults.text = coins.map { "\($0.name) (\($0.code))" }.joined(separator: "\n\n")
    }

}