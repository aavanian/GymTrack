import Foundation

public enum WatchMessageKind: String, Codable {
    case workoutStarted   // phone → watch
    case setCompleted     // watch → phone
    case workoutEnded     // phone → watch
}

public struct WatchMessage: Codable {
    public let kind: WatchMessageKind
    // workoutStarted payload
    public let exercises: [Exercise]?
    public let sessionType: SessionType?
    // setCompleted payload
    public let exerciseId: String?
    public let completedSets: Int?

    public init(
        kind: WatchMessageKind,
        exercises: [Exercise]? = nil,
        sessionType: SessionType? = nil,
        exerciseId: String? = nil,
        completedSets: Int? = nil
    ) {
        self.kind = kind
        self.exercises = exercises
        self.sessionType = sessionType
        self.exerciseId = exerciseId
        self.completedSets = completedSets
    }
}

#if os(iOS)
import Combine

public protocol WatchCompanionManaging: AnyObject {
    var isWatchReachable: Bool { get }
    func sendWorkoutStarted(_ exercises: [Exercise], sessionType: SessionType)
    func sendWorkoutEnded()
    var setCompletedPublisher: AnyPublisher<(exerciseId: String, count: Int), Never> { get }
}
#endif
