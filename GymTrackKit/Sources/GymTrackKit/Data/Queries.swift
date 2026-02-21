import Foundation
import GRDB

public enum Queries {
    // MARK: - Sessions

    @discardableResult
    public static func insertSession(
        _ db: AppDatabase,
        type: SessionType,
        date: String,
        startedAt: String,
        durationSeconds: Int,
        isPartial: Bool = false
    ) throws -> Session {
        var session = Session(
            sessionType: type,
            date: date,
            startedAt: startedAt,
            durationSeconds: durationSeconds,
            isPartial: isPartial
        )
        try db.dbWriter.write { dbConn in
            try session.insert(dbConn)
        }
        return session
    }

    public static func lastSession(_ db: AppDatabase) throws -> Session? {
        try db.dbWriter.read { db in
            try Session
                .order(Column("id").desc)
                .fetchOne(db)
        }
    }

    public static func sessionsInDateRange(
        _ db: AppDatabase,
        from startDate: String,
        to endDate: String
    ) throws -> [Session] {
        try db.dbWriter.read { db in
            try Session
                .filter(Column("date") >= startDate && Column("date") <= endDate)
                .order(Column("date").desc)
                .fetchAll(db)
        }
    }

    /// All dates with at least one non-partial session
    public static func nonPartialSessionDates(_ db: AppDatabase) throws -> [Date] {
        try db.dbWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT DISTINCT date FROM session WHERE isPartial = 0 ORDER BY date DESC"
            )
            return rows.compactMap { DateHelpers.date(from: $0["date"]) }
        }
    }

    // MARK: - Daily Challenge

    public static func challengeForDate(_ db: AppDatabase, date: String) throws -> DailyChallenge? {
        try db.dbWriter.read { db in
            try DailyChallenge
                .filter(Column("date") == date)
                .fetchOne(db)
        }
    }

    @discardableResult
    public static func upsertChallenge(
        _ db: AppDatabase,
        date: String,
        setsCompleted: Int
    ) throws -> DailyChallenge {
        try db.dbWriter.write { dbConn in
            if var existing = try DailyChallenge.filter(Column("date") == date).fetchOne(dbConn) {
                existing.setsCompleted = setsCompleted
                try existing.update(dbConn)
                return existing
            } else {
                var challenge = DailyChallenge(date: date, setsCompleted: setsCompleted)
                try challenge.insert(dbConn)
                return challenge
            }
        }
    }

    /// Increment challenge sets for a date, capping at 3
    @discardableResult
    public static func incrementChallenge(_ db: AppDatabase, date: String) throws -> DailyChallenge {
        let current = try challengeForDate(db, date: date)
        let newSets = min((current?.setsCompleted ?? 0) + 1, 3)
        return try upsertChallenge(db, date: date, setsCompleted: newSets)
    }

    /// All dates where challenge was fully completed (3 sets)
    public static func completedChallengeDates(_ db: AppDatabase) throws -> [Date] {
        try db.dbWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT date FROM dailyChallenge WHERE setsCompleted = 3 ORDER BY date DESC"
            )
            return rows.compactMap { DateHelpers.date(from: $0["date"]) }
        }
    }

    /// Count of completed challenge days in a date range
    public static func completedChallengeCount(
        _ db: AppDatabase,
        from startDate: String,
        to endDate: String
    ) throws -> Int {
        try db.dbWriter.read { db in
            try DailyChallenge
                .filter(Column("date") >= startDate && Column("date") <= endDate)
                .filter(Column("setsCompleted") == 3)
                .fetchCount(db)
        }
    }

    // MARK: - Workouts & Exercises

    /// Fetch all workouts
    public static func allWorkouts(_ db: AppDatabase) throws -> [Workout] {
        try db.dbWriter.read { dbConn in
            try Workout.fetchAll(dbConn)
        }
    }

    /// Fetch a workout by name
    public static func workoutByName(_ db: AppDatabase, name: String) throws -> Workout? {
        try db.dbWriter.read { dbConn in
            try Workout
                .filter(Column("name") == name)
                .fetchOne(dbConn)
        }
    }

    /// Fetch exercises for a workout, ordered by position.
    /// Returns tuples of (ExerciseRecord, WorkoutExercise) so callers have both
    /// the exercise definition and the per-workout overrides.
    public static func exercisesForWorkout(
        _ db: AppDatabase,
        workoutId: Int64
    ) throws -> [(ExerciseRecord, WorkoutExercise)] {
        try db.dbWriter.read { dbConn in
            let rows = try Row.fetchAll(
                dbConn,
                sql: """
                    SELECT e.id, e.name, e.description, e.advice, e.counterUnit,
                           e.defaultValue, e.isDailyChallenge,
                           we.id AS weId, we.workoutId, we.exerciseId, we.position,
                           we.counterValue, we.counterLabel, we.restSeconds, we.sets
                    FROM workoutExercise we
                    JOIN exercise e ON e.id = we.exerciseId
                    WHERE we.workoutId = ?
                    ORDER BY we.position
                    """,
                arguments: [workoutId]
            )
            return rows.map { row in
                let exercise = ExerciseRecord(
                    id: row["id"],
                    name: row["name"],
                    description: row["description"],
                    advice: row["advice"],
                    counterUnit: row["counterUnit"],
                    defaultValue: row["defaultValue"],
                    isDailyChallenge: row["isDailyChallenge"]
                )
                let we = WorkoutExercise(
                    id: row["weId"],
                    workoutId: row["workoutId"],
                    exerciseId: row["exerciseId"],
                    position: row["position"],
                    counterValue: row["counterValue"],
                    counterLabel: row["counterLabel"],
                    restSeconds: row["restSeconds"],
                    sets: row["sets"]
                )
                return (exercise, we)
            }
        }
    }
}
