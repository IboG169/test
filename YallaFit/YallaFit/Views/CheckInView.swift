import SwiftUI
import CoreData

struct CheckInView: View {
    @StateObject private var viewModel: CheckInViewModel
    @Environment(\.dismiss) private var dismiss

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: CheckInViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weight Input
                    weightSection

                    // Steps Input
                    stepsSection

                    // Calories Input
                    caloriesSection

                    // Strength Training
                    strengthSection

                    // Mood Selector
                    moodSection

                    // Journal
                    journalSection

                    // Save Button
                    saveButton

                    // Feedback messages
                    feedbackSection
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Tageseintrag")
            .confetti(isActive: viewModel.showConfetti)
        }
    }

    // MARK: - Weight

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Gewicht (kg)", systemImage: "scalemass.fill")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            TextField("z.B. 121,5", text: $viewModel.weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
        }
        .cardStyle()
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Schritte", systemImage: "figure.walk")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("Ziel: \(viewModel.stepGoal >= 10000 ? "10.000" : "\(viewModel.stepGoal)")")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            TextField("Schritte eingeben", text: $viewModel.steps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.title3)

            ProgressView(value: viewModel.stepsProgress)
                .tint(viewModel.stepsInt >= viewModel.stepGoal ? .green : Theme.accentBlue)
                .scaleEffect(y: 1.5)

            if viewModel.stepsInt >= viewModel.stepGoal {
                Text("Mashallah! Ueber Ziel! \u{1F389}")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
        }
        .cardStyle()
    }

    // MARK: - Calories

    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Kalorien (kcal)", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("Ziel: \(viewModel.calorieGoal >= 2400 ? "2.400" : "\(viewModel.calorieGoal)") kcal")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            TextField("Kalorien eingeben", text: $viewModel.calories)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.title3)

            ProgressView(value: viewModel.caloriesProgress)
                .tint(viewModel.caloriesInt <= viewModel.calorieGoal ? Theme.accentBlue : .orange)
                .scaleEffect(y: 1.5)
        }
        .cardStyle()
    }

    // MARK: - Strength Training

    private var strengthSection: some View {
        HStack {
            Label("Krafttraining", systemImage: "dumbbell.fill")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Toggle("", isOn: $viewModel.strengthTraining)
                .tint(Theme.accentBlue)
        }
        .cardStyle()
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stimmung")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Button(action: { viewModel.selectedMood = index }) {
                        Text(Theme.moodEmojis[index])
                            .font(.system(size: viewModel.selectedMood == index ? 44 : 32))
                            .scaleEffect(viewModel.selectedMood == index ? 1.1 : 1.0)
                            .opacity(viewModel.selectedMood == index ? 1.0 : 0.5)
                            .animation(.spring(response: 0.3), value: viewModel.selectedMood)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Journal

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Wie war dein Tag?", systemImage: "pencil.and.list.clipboard")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            TextEditor(text: $viewModel.journalEntry)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                )
        }
        .cardStyle()
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            viewModel.saveEntry()
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.saved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                Text(viewModel.saved ? "Gespeichert!" : "Tag speichern")
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.saved ? Color.green : Theme.accentBlue)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(viewModel.saved)
        .animation(.easeInOut, value: viewModel.saved)
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(spacing: 8) {
            if viewModel.stepsOverGoal {
                Text("Mashallah! Ueber Ziel! \u{1F389}")
                    .font(.headline)
                    .foregroundColor(.green)
                    .transition(.scale)
            }

            if let message = viewModel.calorieMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.saved)
    }
}
