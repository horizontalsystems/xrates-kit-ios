import GRDB

extension Date {

    var toDebugString: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MM/dd/yy, HH:mm:ss")

        return formatter.string(from: self)
    }

}

extension Decimal: DatabaseValueConvertible {

    public var databaseValue: DatabaseValue {
        NSDecimalNumber(decimal: self).stringValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Decimal? {
        guard case .string(let rawValue) = dbValue.storage else {
            return nil
        }
        return Decimal(string: rawValue)
    }

}
