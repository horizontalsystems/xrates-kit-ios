import UIKit
import SnapKit
import XRatesKit

class TopMarketCell: UITableViewCell {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        return formatter
    }()

    private let titleLabel = UILabel()
    private let dateLabel = UILabel()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(10)
            maker.top.equalToSuperview().offset(10)
        }

        titleLabel.numberOfLines = 2
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)

        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(10)
            maker.leading.equalToSuperview().inset(10)
        }

        dateLabel.font = .systemFont(ofSize: 10)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func string(from decimal: Decimal) -> String {
        Self.formatter.string(from: decimal as NSNumber) ?? "N/A"
    }

    func bind(topMarket: TopMarket) {
        titleLabel.text = """
                          \(topMarket.coin.title) : \(topMarket.coin.code.uppercased()). Volume: \(string(from: topMarket.marketInfo.volume))
                          Rate: \(string(from: topMarket.marketInfo.rate)). RateDiff: \(string(from: topMarket.marketInfo.rateDiffPeriod)). 
                          """

        dateLabel.text = TopMarketCell.dateFormatter.string(from: Date(timeIntervalSince1970: topMarket.marketInfo.timestamp))
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
