import SwiftUI
import Charts
import CoreData

struct YallaFitProgressView: View {
    @StateObject private var viewModel: ProgressViewModel

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weight Chart
                    weightChartSection

                    // Steps Chart
                    stepsChartSection

                    // Calories Chart
                    caloriesChartSection

                    // Monthly Summary
                    monthlySummarySection

                    // Milestones
                    milestonesSection
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Fortschritt")
            .onAppear { viewModel.loadData() }
        }
    }

    // MARK: - Weight Chart

    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Gewichtsverlauf (Wochen)", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if viewModel.weightData.isEmpty {
                emptyChartPlaceholder("Noch keine Gewichtsdaten")
            } else {
                Chart(viewModel.weightData) { point in
                    LineMark(
                        x: .value("Datum", point.label),
                        y: .value("Gewicht", point.value)
                    )
                    .foregroundStyle(Theme.accentBlue)
                    .symbol(.circle)

                    PointMark(
                        x: .value("Datum", point.label),
                        y: .value("Gewicht", point.value)
                    )
                    .foregroundStyle(Theme.accentBlue)
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", point.value).replacingOccurrences(of: ".", with: ","))
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 200)
            }
        }
        .cardStyle()
    }

    // MARK: - Steps Chart

    private var stepsChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Schritte (letzte 7 Tage)", systemImage: "figure.walk")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if viewModel.stepsData.isEmpty {
                emptyChartPlaceholder("Noch keine Schrittdaten")
            } else {
                let stepGoal = UserDefaults.standard.integer(forKey: "stepGoal")
                let goal = stepGoal == 0 ? 10000 : stepGoal

                Chart {
                    ForEach(viewModel.stepsData) { point in
                        BarMark(
                            x: .value("Tag", point.label),
                            y: .value("Schritte", point.value)
                        )
                        .foregroundStyle(point.value >= Double(goal) ? Color.green : Theme.accentBlue)
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Ziel", goal))
                        .foregroundStyle(Theme.gold)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Ziel")
                                .font(.caption2)
                                .foregroundColor(Theme.gold)
                        }
                }
                .frame(height: 200)
            }
        }
        .cardStyle()
    }

    // MARK: - Calories Chart

    private var caloriesChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kalorien (letzte 7 Tage)", systemImage: "flame.fill")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if viewModel.caloriesData.isEmpty {
                emptyChartPlaceholder("Noch keine Kaloriendaten")
            } else {
                let calGoal = UserDefaults.standard.integer(forKey: "calorieGoal")
                let goal = calGoal == 0 ? 2400 : calGoal

                Chart {
                    ForEach(viewModel.caloriesData) { point in
                        BarMark(
                            x: .value("Tag", point.label),
                            y: .value("Kalorien", point.value)
                        )
                        .foregroundStyle(point.value <= Double(goal) ? Theme.accentBlue : Color.orange)
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Ziel", goal))
                        .foregroundStyle(Theme.gold)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Ziel")
                                .font(.caption2)
                                .foregroundColor(Theme.gold)
                        }
                }
                .frame(height: 200)
            }
        }
        .cardStyle()
    }

    // MARK: - Monthly Summary

    private var monthlySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monats\u{00FC}bersicht", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if let summary = viewModel.monthlySummary {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryCard(icon: "figure.walk", title: "Schritte/Tag", value: "\(summary.avgSteps)", color: Theme.accentBlue)
                    summaryCard(icon: "flame.fill", title: "kcal/Tag", value: "\(summary.avgCalories)", color: .orange)
                    summaryCard(icon: "dumbbell.fill", title: "Trainingstage", value: "\(summary.trainingDays)", color: .green)
                    summaryCard(icon: "checkmark.circle.fill", title: "Eintraege", value: "\(summary.totalDays)", color: Theme.gold)
                }
            } else {
                Text("Noch keine Daten diesen Monat")
                    .foregroundColor(Theme.textSecondary)
                    .font(.subheadline)
            }
        }
        .cardStyle()
    }

    private func summaryCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Meilensteine", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundColor(Theme.gold)

            Text("Gewicht")
                .font(.subheadline.bold())
                .foregroundColor(Theme.textSecondary)

            ForEach(viewModel.weightMilestones) { milestone in
                milestoneRow(milestone)
            }

            Divider()

            Text("Streak")
                .font(.subheadline.bold())
                .foregroundColor(Theme.textSecondary)

            ForEach(viewModel.streakMilestones) { milestone in
                milestoneRow(milestone)
            }
        }
        .cardStyle()
    }

    private func milestoneRow(_ milestone: Milestone) -> some View {
        HStack(spacing: 12) {
            Text(milestone.icon)
                .font(.title2)
                .opacity(milestone.achieved ? 1.0 : 0.3)

            Text(milestone.label)
                .font(.subheadline)
                .foregroundColor(milestone.achieved ? Theme.textPrimary : Theme.textSecondary)

            Spacer()

            if milestone.achieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(Theme.textSecondary.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }

    private func emptyChartPlaceholder(_ text: String) -> some View {
        Text(text)
            .foregroundColor(Theme.textSecondary)
            .font(.subheadline)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
    }
}
