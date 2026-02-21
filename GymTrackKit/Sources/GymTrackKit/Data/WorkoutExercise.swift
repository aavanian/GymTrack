import Foundation
import GRDB

public struct WorkoutExercise: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: Int64?
    public var workoutId: Int64
    public var exerciseId: Int64
    public var position: Int
    public var counterValue: Int?
    public var counterLabel: String?
    public var restSeconds: Int
    public var sets: Int

    public static var databaseTableName: String { "workoutExercise" }

    public init(
        id: Int64? = nil,
        workoutId: Int64,
        exerciseId: Int64,
        position: Int,
        counterValue: Int? = nil,
        counterLabel: String? = nil,
        restSeconds: Int = 30,
        sets: Int = 1
    ) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.position = position
        self.counterValue = counterValue
        self.counterLabel = counterLabel
        self.restSeconds = restSeconds
        self.sets = sets
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
