import Foundation
import GRDB

public struct Workout: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public var id: Int64?
    public var name: String
    public var description: String

    public static var databaseTableName: String { "workout" }

    public init(
        id: Int64? = nil,
        name: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
