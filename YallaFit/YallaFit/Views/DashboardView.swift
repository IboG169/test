import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var weightInput: String = ""
    @State private var showWeightInput = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Streak
                    if let streakMsg = viewModel.streakMessage {
                        Text(streakMsg)
                            .font(.headline)
                            .foregroundColor(Theme.gold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.gold.opacity(0.15))
                            .cornerRadius(12)
                    }

                    // Weight Progress
                    weightProgressSection

                    // Today's Stats
                    todayStatsSection

                    // Phase 1 Countdown
                    countdownSection

                    // Quote of the day
                    quoteSection
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("YallaFit")
                        .font(.title2.bold())
                        .foregroundColor(Theme.accentBlue)
                }
            }
            .onAppear { viewModel.loadData() }
            .confetti(isActive: viewModel.showConfetti)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Yalla, \(viewModel.userName)!")
                .font(.largeTitle.bold())
                .foregroundColor(Theme.accentBlue)

            Text("Tag \(viewModel.streak > 0 ? "\(viewModel.streak)" : "1") deiner Reise")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Weight Progress

    private var weightProgressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Gewicht")
                    .font(.headline)
                Spacer()
                Button(action: { showWeightInput.toggle() }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(Theme.accentBlue)
                        .font(.title3)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", viewModel.latestWeight).replacingOccurrences(of: ".", with: ","))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("kg")
                    .font(.title3)
                    .foregroundColor(Theme.textSecondary)
            }

            if showWeightInput {
                HStack {
                    TextField("Gewicht eingeben", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Button("OK") {
                        viewModel.saveWeight(weightInput)
                        weightInput = ""
                        showWeightInput = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentBlue)
                }
            }

            // Progress bar
            VStack(spacing: 6) {
                ProgressView(value: viewModel.weightProgress)
                    .tint(Theme.progressColor(for: viewModel.weightProgress))
                    .scaleEffect(y: 2)

                HStack {
                    Text(String(format: "%.1f kg", viewModel.startWeight).replacingOccurrences(of: ".", with: ","))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f kg verloren", viewModel.weightLost).replacingOccurrences(of: ".", with: ","))
                        .font(.caption.bold())
                        .foregroundColor(Theme.gold)
                    Spacer()
                    Text(String(format: "%.1f kg", viewModel.goalWeight).replacingOccurrences(of: ".", with: ","))
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Today Stats

    private var todayStatsSection: some View {
        VStack(spacing: 12) {
            Text("Heute")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let entry = viewModel.todayEntry {
                HStack(spacing: 16) {
                    statItem(
                        icon: "figure.walk",
                        value: "\(entry.steps)",
                        label: "Schritte",
                        color: entry.steps >= Int32(viewModel.stepGoal) ? .green : Theme.accentBlue
                    )
                    statItem(
                        icon: "flame.fill",
                        value: "\(entry.calories)",
                        label: "kcal",
                        color: entry.calories <= Int32(viewModel.calorieGoal) ? .green : .orange
                    )
                    statItem(
                        icon: "dumbbell.fill",
                        value: entry.strengthTraining ? "Ja" : "Nein",
                        label: "Training",
                        color: entry.strengthTraining ? .green : Theme.textSecondary
                    )
                    VStack(spacing: 4) {
                        Text(entry.moodEmoji)
                            .font(.title)
                        Text("Stimmung")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            } else {
                Text("Noch kein Eintrag heute")
                    .foregroundColor(Theme.textSecondary)
                    .font(.subheadline)
                    .padding(.vertical, 8)
            }
        }
        .cardStyle()
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Countdown

    private var countdownSection: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(Theme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Phase 1 Countdown")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text("Noch \(viewModel.phase1Countdown) Tage bis 26. September 2026")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.textPrimary)
            }
            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Quote

    private var quoteSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .foregroundColor(Theme.gold)
                .font(.title3)
            Text(viewModel.quote)
                .font(.subheadline)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Theme.accentBlue.opacity(0.1), Theme.gold.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

import CoreData
