import UIKit
import SnapKit

class NewsHeaderView: UITableViewHeaderFooterView {
    private let titleLabel = UILabel()

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        contentView.backgroundColor = .lightGray

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(10)
            maker.top.equalToSuperview().offset(10)
        }

        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .black
    }

    func bind(title: String) {
        titleLabel.text = title
    }

}
