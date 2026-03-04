import SwiftUI
import OpenWOKit

struct WorkoutSessionView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var currentIndex: Int = 0

    var body: some View {
        if sessionManager.workoutActive && !sessionManager.exercises.isEmpty {
            activeView
        } else {
            waitingView
        }
    }

    private var waitingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.right.inward")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Start a workout\non your iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var activeView: some View {
        TabView(selection: $currentIndex) {
            ForEach(sessionManager.exercises.indices, id: \.self) { index in
                let exercise = sessionManager.exercises[index]
                ExerciseCardView(
                    exercise: exercise,
                    position: "\(index + 1)/\(sessionManager.exercises.count)",
                    completedSets: sessionManager.completedSets[exercise.id] ?? 0,
                    onSetTapped: { count in
                        sessionManager.sendSetCompleted(exerciseId: exercise.id, count: count)
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page)
    }
}
