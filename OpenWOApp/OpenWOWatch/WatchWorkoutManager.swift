import Foundation
import HealthKit

final class WatchWorkoutManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    func startWorkout(activityType: HKWorkoutActivityType) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let workoutType = HKObjectType.workoutType()
        try? await healthStore.requestAuthorization(toShare: [workoutType], read: [])

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )

        let startDate = Date()
        session.startActivity(with: startDate)
        try await builder.beginCollection(at: startDate)

        self.workoutSession = session
        self.workoutBuilder = builder
    }

    func endWorkout() async throws {
        guard let session = workoutSession, let builder = workoutBuilder else { return }
        self.workoutSession = nil
        self.workoutBuilder = nil
        let endDate = Date()
        session.end()
        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }

    func discardWorkout() async {
        guard let session = workoutSession, let builder = workoutBuilder else { return }
        self.workoutSession = nil
        self.workoutBuilder = nil
        session.end()
        try? await builder.endCollection(at: Date())
        builder.discardWorkout()
    }
}
