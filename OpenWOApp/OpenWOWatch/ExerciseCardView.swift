import SwiftUI
import OpenWOKit

struct ExerciseCardView: View {
    let exercise: Exercise
    let position: String
    let completedSets: Int
    let onSetTapped: (Int) -> Void

    @State private var localSets: Int

    init(exercise: Exercise, position: String, completedSets: Int, onSetTapped: @escaping (Int) -> Void) {
        self.exercise = exercise
        self.position = position
        self.completedSets = completedSets
        self.onSetTapped = onSetTapped
        self._localSets = State(initialValue: completedSets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(position)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(exercise.reps)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let totalSets = exercise.sets, totalSets > 0 {
                SetTracker(
                    totalSets: totalSets,
                    onAllCompleted: {},
                    completedSets: Binding(
                        get: { localSets },
                        set: { newCount in
                            localSets = newCount
                            onSetTapped(newCount)
                        }
                    )
                )
            }

            if exercise.isTimed {
                TimerView(label: exercise.reps)
            }
        }
        .padding()
        .onChange(of: completedSets) { _, newValue in
            localSets = newValue
        }
    }
}
