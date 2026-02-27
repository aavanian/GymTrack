#if os(iOS)
import XCTest
import HealthKit
@testable import OpenWOKit

final class MockHealthKitManager: HealthKitManaging {
    var authorizationRequested = false
    var startedWorkouts: [(activityType: HKWorkoutActivityType, startDate: Date)] = []
    var endedAt: [Date] = []
    var discardCount = 0

    func requestAuthorizationIfNeeded() async {
        authorizationRequested = true
    }

    func startWorkout(activityType: HKWorkoutActivityType, startDate: Date) async throws {
        startedWorkouts.append((activityType, startDate))
    }

    func endWorkout(at date: Date) async throws {
        endedAt.append(date)
    }

    func discardWorkout() async {
        discardCount += 1
    }
}

final class HealthKitIntegrationTests: XCTestCase {
    private var db: AppDatabase!
    private var mock: MockHealthKitManager!

    override func setUp() async throws {
        db = try AppDatabase.empty()
        mock = MockHealthKitManager()
    }

    func testInitRequestsAuthAndStartsWorkout() async throws {
        let _ = ExerciseViewModel(database: db, sessionType: .a, healthKitManager: mock)

        // Allow the Task in init to execute
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mock.authorizationRequested)
        XCTAssertEqual(mock.startedWorkouts.count, 1)
        XCTAssertEqual(mock.startedWorkouts.first?.activityType, .traditionalStrengthTraining)
    }

    func testFinishWorkoutEndsHealthKitSession() async throws {
        let vm = ExerciseViewModel(database: db, sessionType: .b, healthKitManager: mock)
        try await Task.sleep(nanoseconds: 100_000_000)

        for exercise in vm.exercises {
            vm.markStepCompleted(exercise.id)
        }
        vm.finishWorkout(feedback: .ok)

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mock.endedAt.count, 1)
        XCTAssertEqual(mock.discardCount, 0)
    }

    func testAbortBeforeFiveMinutesDiscardsWorkout() async throws {
        let vm = ExerciseViewModel(database: db, sessionType: .a, healthKitManager: mock)
        try await Task.sleep(nanoseconds: 100_000_000)

        // elapsedSeconds defaults to 0 (< 300)
        vm.abortWorkout()

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mock.discardCount, 1)
        XCTAssertEqual(mock.endedAt.count, 0)
    }

    func testAbortAfterFiveMinutesEndsWorkout() async throws {
        let vm = ExerciseViewModel(database: db, sessionType: .a, healthKitManager: mock)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Simulate elapsed time >= 5 minutes
        vm.elapsedSeconds = 300
        vm.abortWorkout()

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mock.endedAt.count, 1)
        XCTAssertEqual(mock.discardCount, 0)
    }

    func testNilManagerDoesNotCrash() throws {
        let vm = ExerciseViewModel(database: db, sessionType: .a, healthKitManager: nil)
        vm.startTimer()
        vm.abortWorkout()
        vm.finishWorkout(feedback: .ok)
        // No crash = pass
    }

    func testSessionTypeActivityMapping() {
        XCTAssertEqual(SessionType.a.healthKitActivityType, .traditionalStrengthTraining)
        XCTAssertEqual(SessionType.b.healthKitActivityType, .mixedCardio)
        XCTAssertEqual(SessionType.c.healthKitActivityType, .traditionalStrengthTraining)
    }
}
#endif
