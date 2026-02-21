import XCTest
@testable import GymTrackKit

final class DatabaseTests: XCTestCase {
    func testInMemoryDatabaseCreates() throws {
        let db = try AppDatabase.empty()
        XCTAssertNotNil(db)
    }

    func testTablesExist() throws {
        let db = try AppDatabase.empty()
        let tableNames = try db.dbWriter.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        }
        XCTAssertTrue(tableNames.contains("session"))
        XCTAssertTrue(tableNames.contains("dailyChallenge"))
        XCTAssertTrue(tableNames.contains("exercise"))
        XCTAssertTrue(tableNames.contains("workout"))
        XCTAssertTrue(tableNames.contains("workoutExercise"))
    }

    func testSeedDataPopulated() throws {
        let db = try AppDatabase.empty()

        let exerciseCount = try db.dbWriter.read { dbConn in
            try Int.fetchOne(dbConn, sql: "SELECT COUNT(*) FROM exercise")
        }
        XCTAssertEqual(exerciseCount, 12)

        let workoutCount = try db.dbWriter.read { dbConn in
            try Int.fetchOne(dbConn, sql: "SELECT COUNT(*) FROM workout")
        }
        XCTAssertEqual(workoutCount, 3)

        let weCount = try db.dbWriter.read { dbConn in
            try Int.fetchOne(dbConn, sql: "SELECT COUNT(*) FROM workoutExercise")
        }
        // Day A: 9 + Day B: 7 + Day C: 7 = 23
        XCTAssertEqual(weCount, 23)
    }
}
