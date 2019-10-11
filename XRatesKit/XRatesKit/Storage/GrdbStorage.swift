import GRDB
import RxSwift
import RxGRDB

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

        migrator.registerMigration("createRate") { db in
            try db.create(table: Rate.databaseTableName) { t in
                t.column(Rate.Columns.coinCode.name, .text).notNull()
                t.column(Rate.Columns.currencyCode.name, .text).notNull()
                t.column(Rate.Columns.value.name, .text).notNull()
                t.column(Rate.Columns.date.name, .double).notNull()
                t.column(Rate.Columns.isLatest.name, .boolean).notNull()

                t.primaryKey([
                    Rate.Columns.coinCode.name,
                    Rate.Columns.currencyCode.name,
                    Rate.Columns.date.name,
                    Rate.Columns.isLatest.name
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
        migrator.registerMigration("createChartStats") { db in
            try db.create(table: ChartStats.databaseTableName) { t in
                t.column(ChartStats.Columns.coinCode.name, .text).notNull()
                t.column(ChartStats.Columns.currencyCode.name, .text).notNull()
                t.column(ChartStats.Columns.chartType.name, .integer).notNull()
                t.column(ChartStats.Columns.timestamp.name, .double).notNull()
                t.column(ChartStats.Columns.value.name, .text).notNull()

                t.primaryKey([
                    ChartStats.Columns.coinCode.name,
                    ChartStats.Columns.currencyCode.name,
                    ChartStats.Columns.chartType.name,
                ], onConflict: .replace)
            }
        }
        return migrator
    }

}

extension GrdbStorage: ILatestRateStorage {

    func latestRate(coinCode: String, currencyCode: String) -> Rate? {
        try! dbPool.read { db in
            try Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.isLatest == true).fetchOne(db)
        }
    }

    func save(rates: [Rate]) {
        _ = try? dbPool.write { db in
            for rate in rates {
                try Rate.filter(Rate.Columns.coinCode == rate.coinCode && Rate.Columns.currencyCode == rate.currencyCode && Rate.Columns.isLatest == true).deleteAll(db)
                try rate.insert(db)
            }
        }
    }

}

extension GrdbStorage: IHistoricalRateStorage {

    func rate(coinCode: String, currencyCode: String, date: Date) -> Rate? {
        try! dbPool.read { db in
            try Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.date == date && Rate.Columns.isLatest == false).fetchOne(db)
        }
    }

    func save(rate: Rate) {
        _ = try? dbPool.write { db in
            try rate.insert(db)
        }
    }

}

extension GrdbStorage: IChartStatsStorage {

    func marketStats(coinCodes: [String], currencyCode: String) -> [MarketStats] {
        let codesForQuery = coinCodes.map { "'\($0)'" }.joined(separator: ",")
        return try! dbPool.read { db in
            try MarketStats.fetchAll(db, sql: "SELECT * FROM market_stats WHERE coinCode IN (\(codesForQuery)) AND currencyCode = '\(currencyCode)'")
        }
    }

    func save(marketStats: MarketStats) {
        _ = try? dbPool.write { db in
            try marketStats.insert(db)
        }
    }

    func chartStatList(coinCode: String, currencyCode: String, chartType: ChartType) -> [ChartStats] {
        try! dbPool.read { db in
            try ChartStats.filter(ChartStats.Columns.coinCode == coinCode && ChartStats.Columns.currencyCode == currencyCode && ChartStats.Columns.chartType == chartType.rawValue)
                    .order(ChartStats.Columns.timestamp).fetchAll(db)
        }
    }

    func save(chartStatList: [ChartStats]) {
        _ = try? dbPool.write { db in
            for chartStats in chartStatList {
                try chartStats.insert(db)
            }
        }
    }

}
