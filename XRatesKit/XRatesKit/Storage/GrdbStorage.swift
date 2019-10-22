import GRDB
import RxSwift

class GrdbStorage {
    private let dbPool: DatabasePool

    init() {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("XRatesKit.sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createLatestRates") { db in
            try db.create(table: LatestRate.databaseTableName) { t in
                t.column(LatestRate.Columns.coinCode.name, .text).notNull()
                t.column(LatestRate.Columns.currencyCode.name, .text).notNull()
                t.column(LatestRate.Columns.value.name, .text).notNull()
                t.column(LatestRate.Columns.timestamp.name, .double).notNull()

                t.primaryKey([
                    LatestRate.Columns.coinCode.name,
                    LatestRate.Columns.currencyCode.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createHistoricalRates") { db in
            try db.create(table: HistoricalRate.databaseTableName) { t in
                t.column(HistoricalRate.Columns.coinCode.name, .text).notNull()
                t.column(HistoricalRate.Columns.currencyCode.name, .text).notNull()
                t.column(HistoricalRate.Columns.value.name, .text).notNull()
                t.column(HistoricalRate.Columns.timestamp.name, .double).notNull()

                t.primaryKey([
                    HistoricalRate.Columns.coinCode.name,
                    HistoricalRate.Columns.currencyCode.name,
                    HistoricalRate.Columns.timestamp.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createChartPoints") { db in
            try db.create(table: ChartPointRecord.databaseTableName) { t in
                t.column(ChartPointRecord.Columns.coinCode.name, .text).notNull()
                t.column(ChartPointRecord.Columns.currencyCode.name, .text).notNull()
                t.column(ChartPointRecord.Columns.chartType.name, .integer).notNull()
                t.column(ChartPointRecord.Columns.timestamp.name, .double).notNull()
                t.column(ChartPointRecord.Columns.value.name, .text).notNull()

                t.primaryKey([
                    ChartPointRecord.Columns.coinCode.name,
                    ChartPointRecord.Columns.currencyCode.name,
                    ChartPointRecord.Columns.chartType.name,
                    ChartPointRecord.Columns.timestamp.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createMarketStats") { db in
            try db.create(table: MarketStats.databaseTableName) { t in
                t.column(MarketStats.Columns.coinCode.name, .text).notNull()
                t.column(MarketStats.Columns.currencyCode.name, .text).notNull()
                t.column(MarketStats.Columns.date.name, .double).notNull()
                t.column(MarketStats.Columns.volume.name, .text).notNull()
                t.column(MarketStats.Columns.marketCap.name, .text).notNull()
                t.column(MarketStats.Columns.supply.name, .text).notNull()

                t.primaryKey([
                    MarketStats.Columns.coinCode.name,
                    MarketStats.Columns.currencyCode.name,
                ], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension GrdbStorage: ILatestRateStorage {

    func latestRate(key: RateKey) -> LatestRate? {
        try! dbPool.read { db in
            try LatestRate.filter(LatestRate.Columns.coinCode == key.coinCode && LatestRate.Columns.currencyCode == key.currencyCode).fetchOne(db)
        }
    }

    func latestRatesSortedByTimestamp(coinCodes: [String], currencyCode: String) -> [LatestRate] {
        try! dbPool.read { db in
            try LatestRate
                    .filter(coinCodes.contains(LatestRate.Columns.coinCode) && LatestRate.Columns.currencyCode == currencyCode)
                    .order(LatestRate.Columns.timestamp)
                    .fetchAll(db)
        }
    }

    func save(latestRates: [LatestRate]) {
        _ = try! dbPool.write { db in
            for rate in latestRates {
                try rate.insert(db)
            }
        }
    }

}

extension GrdbStorage: IHistoricalRateStorage {

    func rate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> HistoricalRate? {
        try! dbPool.read { db in
            try HistoricalRate
                    .filter(HistoricalRate.Columns.coinCode == coinCode && HistoricalRate.Columns.currencyCode == currencyCode && HistoricalRate.Columns.timestamp == timestamp)
                    .fetchOne(db)
        }
    }

    func save(historicalRate: HistoricalRate) {
        _ = try! dbPool.write { db in
            try historicalRate.insert(db)
        }
    }

}

extension GrdbStorage: IChartPointStorage {

//    func marketStats(coinCodes: [String], currencyCode: String) -> [MarketStats] {
//        let codesForQuery = coinCodes.map { "'\($0)'" }.joined(separator: ",")
//        return try! dbPool.read { db in
//            try MarketStats.fetchAll(db, sql: "SELECT * FROM market_stats WHERE coinCode IN (\(codesForQuery)) AND currencyCode = '\(currencyCode)'")
//        }
//    }
//
//    func save(marketStats: MarketStats) {
//        _ = try! dbPool.write { db in
//            try marketStats.insert(db)
//        }
//    }

    func chartPointRecords(key: ChartInfoKey, fromTimestamp: TimeInterval) -> [ChartPointRecord] {
        try! dbPool.read { db in
            try ChartPointRecord
                    .filter(ChartPointRecord.Columns.coinCode == key.coinCode && ChartPointRecord.Columns.currencyCode == key.currencyCode && ChartPointRecord.Columns.chartType == key.chartType.rawValue)
                    .filter(ChartPointRecord.Columns.timestamp >= fromTimestamp)
                    .order(ChartPointRecord.Columns.timestamp).fetchAll(db)
        }
    }

    func save(chartPointRecords: [ChartPointRecord]) {
        _ = try! dbPool.write { db in
            for record in chartPointRecords {
                try record.insert(db)
            }
        }
    }

    func deleteChartPointRecords(key: ChartInfoKey) {
        _ = try! dbPool.write { db in
            try ChartPointRecord
                    .filter(ChartPointRecord.Columns.coinCode == key.coinCode && ChartPointRecord.Columns.currencyCode == key.currencyCode && ChartPointRecord.Columns.chartType == key.chartType.rawValue)
                    .deleteAll(db)
        }
    }

}
