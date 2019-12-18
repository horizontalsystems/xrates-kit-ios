import UIKit
import SnapKit
import XRatesKit

class MarketInfoCell: UITableViewCell {
    private let coinCodeLabel = UILabel()
    private let rateLabel = UILabel()
    private let diffLabel = UILabel()
    private let marketInfoLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(coinCodeLabel)
        coinCodeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(10)
            maker.top.equalToSuperview().offset(10)
        }

        coinCodeLabel.font = .systemFont(ofSize: 14, weight: .medium)

        contentView.addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(10)
            maker.trailing.equalToSuperview().inset(50)
        }

        rateLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        contentView.addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(rateLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(10)
        }

        diffLabel.font = .systemFont(ofSize: 12)

        contentView.addSubview(marketInfoLabel)
        marketInfoLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(10)
            maker.bottom.equalToSuperview().inset(10)
        }

        marketInfoLabel.numberOfLines = 0
        marketInfoLabel.font = .systemFont(ofSize: 10)
        marketInfoLabel.textColor = .lightGray

        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(10)
            maker.top.equalTo(rateLabel.snp.bottom).offset(5)
        }

        dateLabel.font = .systemFont(ofSize: 10)
        dateLabel.textColor = .lightGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(coinCode: String, marketInfo: MarketInfo?) {
        coinCodeLabel.text = coinCode

        if let marketInfo = marketInfo {
            rateLabel.text = MarketInfoCell.rateFormatter.string(from: marketInfo.rate as NSNumber)
            rateLabel.textColor = marketInfo.expired ? .lightGray : .black

            diffLabel.text = MarketInfoCell.rateFormatter.string(from: marketInfo.diff as NSNumber)

            let volumeText = MarketInfoCell.marketInfoFormatter.string(from: marketInfo.volume as NSNumber) ?? "n/a"
            let marketCapText = MarketInfoCell.marketInfoFormatter.string(from: marketInfo.marketCap as NSNumber) ?? "n/a"
            let supplyText = MarketInfoCell.marketInfoFormatter.string(from: marketInfo.supply as NSNumber) ?? "n/a"
            marketInfoLabel.text = "VLM: \(volumeText)\nMKC: \(marketCapText)\nSPL: \(supplyText)"

            dateLabel.text = MarketInfoCell.dateFormatter.string(from: Date(timeIntervalSince1970: marketInfo.timestamp))
        } else {
            rateLabel.text = nil
            diffLabel.text = "n/a"
            marketInfoLabel.text = nil
            dateLabel.text = nil
        }
    }

}

extension MarketInfoCell {

    static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let marketInfoFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d, hh:mm:ss"
        return formatter
    }()

}
