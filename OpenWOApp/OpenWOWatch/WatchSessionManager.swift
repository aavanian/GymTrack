import Foundation
import WatchConnectivity
import OpenWOKit

final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {

    @Published var exercises: [Exercise] = []
    @Published var sessionType: SessionType?
    @Published var workoutActive: Bool = false
    @Published var completedSets: [String: Int] = [:]

    private let workoutManager = WatchWorkoutManager()
    private let wcSession = WCSession.default

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        wcSession.delegate = self
        wcSession.activate()
    }

    // MARK: - Set completion

    func sendSetCompleted(exerciseId: String, count: Int) {
        completedSets[exerciseId] = count
        let message = WatchMessage(
            kind: .setCompleted,
            exerciseId: exerciseId,
            completedSets: count
        )
        guard let data = try? JSONEncoder().encode(message) else { return }
        let payload: [String: Any] = ["msg": data]
        if wcSession.isReachable {
            wcSession.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            wcSession.transferUserInfo(payload)
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decode(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        decode(userInfo)
    }

    private func decode(_ payload: [String: Any]) {
        guard let data = payload["msg"] as? Data,
              let msg = try? JSONDecoder().decode(WatchMessage.self, from: data)
        else { return }

        DispatchQueue.main.async {
            switch msg.kind {
            case .workoutStarted:
                self.exercises = msg.exercises ?? []
                self.sessionType = msg.sessionType
                self.completedSets = [:]
                self.workoutActive = true
                if let type = msg.sessionType {
                    Task {
                        try? await self.workoutManager.startWorkout(
                            activityType: type.healthKitActivityType
                        )
                    }
                }
            case .workoutEnded:
                self.workoutActive = false
                self.exercises = []
                self.completedSets = [:]
                Task { try? await self.workoutManager.endWorkout() }
            case .setCompleted:
                break
            }
        }
    }
}
