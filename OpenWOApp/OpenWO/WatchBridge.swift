import Foundation
import WatchConnectivity
import Combine
import OpenWOKit

public final class WatchBridge: NSObject, ObservableObject, WCSessionDelegate, WatchCompanionManaging {

    private let session = WCSession.default
    private let setCompletedSubject = PassthroughSubject<(exerciseId: String, count: Int), Never>()

    public var setCompletedPublisher: AnyPublisher<(exerciseId: String, count: Int), Never> {
        setCompletedSubject.eraseToAnyPublisher()
    }

    public var isWatchReachable: Bool {
        session.isReachable
    }

    override public init() {
        super.init()
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - WatchCompanionManaging

    public func sendWorkoutStarted(_ exercises: [Exercise], sessionType: SessionType) {
        let message = WatchMessage(
            kind: .workoutStarted,
            exercises: exercises,
            sessionType: sessionType
        )
        send(message, reliable: true)
    }

    public func sendWorkoutEnded() {
        let message = WatchMessage(kind: .workoutEnded)
        if session.isReachable {
            send(message, reliable: false)
        } else {
            send(message, reliable: true)
        }
    }

    // MARK: - Encoding

    private func send(_ message: WatchMessage, reliable: Bool) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        let payload: [String: Any] = ["msg": data]
        if reliable || !session.isReachable {
            session.transferUserInfo(payload)
        } else {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        decode(message)
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        decode(userInfo)
    }

    private func decode(_ payload: [String: Any]) {
        guard let data = payload["msg"] as? Data,
              let msg = try? JSONDecoder().decode(WatchMessage.self, from: data),
              msg.kind == .setCompleted,
              let exerciseId = msg.exerciseId,
              let count = msg.completedSets
        else { return }
        DispatchQueue.main.async {
            self.setCompletedSubject.send((exerciseId: exerciseId, count: count))
        }
    }
}
