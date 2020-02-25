import UIKit
import SnapKit
import XRatesKit

class PostCell: UITableViewCell {
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

    func bind(title: String, timestamp: TimeInterval?) {
        titleLabel.text = title

        if let timestamp = timestamp {
            dateLabel.text = PostCell.dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
        } else {
            dateLabel.text = nil
        }
    }

}

extension PostCell {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM d, hh:mm:ss"
        return formatter
    }()

}
