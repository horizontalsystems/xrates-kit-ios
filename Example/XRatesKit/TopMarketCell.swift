import UIKit
import SnapKit
import XRatesKit

class TopMarketCell: UITableViewCell {
    private static let favoriteImage = UIImage(named: "rate")?.withRenderingMode(.alwaysTemplate)

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        return formatter
    }()

    private let favoriteButton = UIButton()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()

    var onTapFavorite: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(favoriteButton)
        favoriteButton.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(10)
            maker.size.equalTo(32)
        }

        favoriteButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        favoriteButton.setImage(Self.favoriteImage, for: .normal)
        favoriteButton.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
        set(favorite: false)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(10)
            maker.trailing.equalTo(favoriteButton.snp.leading).offset(10)
            maker.top.equalToSuperview().offset(10)
        }

        titleLabel.numberOfLines = 2
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)

        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(10)
            maker.leading.equalToSuperview().inset(10)
            maker.trailing.equalTo(favoriteButton.snp.leading).offset(10)
        }

        dateLabel.font = .systemFont(ofSize: 10)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func string(from value: Decimal, fractionDigits: Int = 6) -> String {
        Self.formatter.maximumFractionDigits = fractionDigits
        return Self.formatter.string(from: value as NSNumber) ?? "N/A"
    }

    @objc private func onTapButton() {
        onTapFavorite?()
    }

}

extension TopMarketCell {

    func set(favorite: Bool) {
        favoriteButton.tintColor = favorite ? .blue : .gray
    }

    func bind(topMarket: CoinMarket, favorite: Bool, action: (() -> ())?) {
        let volumeString = string(from: topMarket.marketInfo.volume / 1000, fractionDigits: 0) + "k"
        titleLabel.text = """
                          \(topMarket.coin.title) : \(topMarket.coin.code.uppercased()). Volume: \(volumeString)
                          Rate: \(string(from: topMarket.marketInfo.rate, fractionDigits: 4)). RateDiff: \(string(from: topMarket.marketInfo.rateDiffPeriod, fractionDigits: 2)). 
                          """

        dateLabel.text = TopMarketCell.dateFormatter.string(from: Date(timeIntervalSince1970: topMarket.marketInfo.timestamp))

        set(favorite: favorite)
        onTapFavorite = action
    }

}

extension TopMarketCell {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d, hh:mm:ss"
        return formatter
    }()

}
