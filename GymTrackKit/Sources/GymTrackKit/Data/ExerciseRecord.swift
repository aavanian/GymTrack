import Foundation
import GRDB

public struct ExerciseRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: Int64?
    public var name: String
    public var description: String
    public var advice: String
    public var counterUnit: String
    public var defaultValue: Int
    public var isDailyChallenge: Bool

    public static var databaseTableName: String { "exercise" }

    public init(
        id: Int64? = nil,
        name: String,
        description: String = "",
        advice: String = "",
        counterUnit: String,
        defaultValue: Int,
        isDailyChallenge: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.advice = advice
        self.counterUnit = counterUnit
        self.defaultValue = defaultValue
        self.isDailyChallenge = isDailyChallenge
    }

    public var isTimed: Bool {
        counterUnit == "timer"
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
