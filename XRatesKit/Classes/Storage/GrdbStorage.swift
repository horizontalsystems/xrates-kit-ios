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

        migrator.registerMigration("createMarketInfo") { db in
            try db.create(table: MarketInfoRecord.databaseTableName) { t in
                t.column(MarketInfoRecord.Columns.coinCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.currencyCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.timestamp.name, .double).notNull()
                t.column(MarketInfoRecord.Columns.rate.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.open24Hour.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.diff.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.volume.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.marketCap.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.supply.name, .text).notNull()

                t.primaryKey([
                    MarketInfoRecord.Columns.coinCode.name,
                    MarketInfoRecord.Columns.currencyCode.name,
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
        migrator.registerMigration("addVolumeToChartPoints") { db in 
            try db.execute(sql: "DELETE from \(ChartPointRecord.databaseTableName)")
            try db.alter(table: ChartPointRecord.databaseTableName) { t in
                t.add(column: ChartPointRecord.Columns.volume.name, .text)
            }
        }

        migrator.registerMigration("createTopMarketInfo") { db in
            try db.create(table: TopMarketInfoRecord.databaseTableName) { t in
                t.column(TopMarketInfoRecord.Columns.coinCode.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.coinName.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.currencyCode.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.timestamp.name, .double).notNull()
                t.column(TopMarketInfoRecord.Columns.rate.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.open24Hour.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.diff.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.volume.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.marketCap.name, .text).notNull()
                t.column(TopMarketInfoRecord.Columns.supply.name, .text).notNull()

                t.primaryKey([
                    TopMarketInfoRecord.Columns.coinCode.name,
                    TopMarketInfoRecord.Columns.currencyCode.name,
                ], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension GrdbStorage: IMarketInfoStorage {

    func marketInfoRecord(key: PairKey) -> MarketInfoRecord? {
        try! dbPool.read { db in
            try MarketInfoRecord.filter(MarketInfoRecord.Columns.coinCode == key.coinCode && MarketInfoRecord.Columns.currencyCode == key.currencyCode).fetchOne(db)
        }
    }

    func marketInfoRecordsSortedByTimestamp(coinCodes: [String], currencyCode: String) -> [MarketInfoRecord] {
        try! dbPool.read { db in
            try MarketInfoRecord
                    .filter(coinCodes.contains(MarketInfoRecord.Columns.coinCode) && MarketInfoRecord.Columns.currencyCode == currencyCode)
                    .order(MarketInfoRecord.Columns.timestamp)
                    .fetchAll(db)
        }
    }

    func save(marketInfoRecords: [MarketInfoRecord]) {
        _ = try! dbPool.write { db in
            for rate in marketInfoRecords {
                try rate.insert(db)
            }
        }
    }

}

extension GrdbStorage: ITopMarketsStorage {

    func topMarketInfoRecords(currencyCode: String) -> [TopMarketInfoRecord] {
        try! dbPool.read { db in
            try TopMarketInfoRecord.filter(TopMarketInfoRecord.Columns.currencyCode == currencyCode).fetchAll(db)
        }
    }

    func save(topMarketInfoRecords: [TopMarketInfoRecord]) {
        _ = try! dbPool.write { db in
            for marketInfo in topMarketInfoRecords {
                try marketInfo.insert(db)
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
