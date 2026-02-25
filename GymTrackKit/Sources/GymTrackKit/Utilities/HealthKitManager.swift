#if os(iOS)
import HealthKit

public protocol HealthKitManaging: AnyObject {
    func requestAuthorizationIfNeeded() async
    func startWorkout(activityType: HKWorkoutActivityType, startDate: Date) async throws
    func endWorkout(at date: Date) async throws
    func discardWorkout() async
}

public final class HealthKitManager: HealthKitManaging {
    private let healthStore = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?

    public init() {}

    public func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        guard status == .notDetermined else { return }

        try? await healthStore.requestAuthorization(toShare: [workoutType], read: [])
    }

    public func startWorkout(activityType: HKWorkoutActivityType, startDate: Date) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        try await builder.beginCollection(at: startDate)
        self.workoutBuilder = builder
    }

    public func endWorkout(at date: Date) async throws {
        guard let builder = workoutBuilder else { return }
        self.workoutBuilder = nil

        try await builder.endCollection(at: date)
        try await builder.finishWorkout()
    }

    public func discardWorkout() async {
        guard let builder = workoutBuilder else { return }
        self.workoutBuilder = nil

        try? await builder.endCollection(at: Date())
        builder.discardWorkout()
    }
}
#endif
