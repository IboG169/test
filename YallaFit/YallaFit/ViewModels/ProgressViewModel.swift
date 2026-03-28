import Foundation
import CoreData

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let date: Date
}

struct MonthlySummary {
    let avgSteps: Int
    let avgCalories: Int
    let trainingDays: Int
    let totalDays: Int
}

class ProgressViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var weightData: [ChartDataPoint] = []
    @Published var stepsData: [ChartDataPoint] = []
    @Published var caloriesData: [ChartDataPoint] = []
    @Published var monthlySummary: MonthlySummary?
    @Published var weightMilestones: [Milestone] = []
    @Published var streakMilestones: [Milestone] = []

    var startWeight: Double {
        UserDefaults.standard.double(forKey: "startWeight").isZero ? 123.5 : UserDefaults.standard.double(forKey: "startWeight")
    }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadData()
    }

    func loadData() {
        loadWeightData()
        loadLast7DaysSteps()
        loadLast7DaysCalories()
        loadMonthlySummary()
        loadMilestones()
    }

    private func loadWeightData() {
        let calendar = Calendar.current
        let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: Date())!

        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND weight > 0", fourWeeksAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: true)]

        guard let entries = try? viewContext.fetch(request) else { return }

        // Group by week and average
        var weeklyData: [Int: (total: Double, count: Int, date: Date)] = [:]
        for entry in entries {
            guard let date = entry.date else { continue }
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            if var existing = weeklyData[weekOfYear] {
                existing.total += entry.weight
                existing.count += 1
                weeklyData[weekOfYear] = existing
            } else {
                weeklyData[weekOfYear] = (entry.weight, 1, date)
            }
        }

        weightData = weeklyData.sorted { $0.value.date < $1.value.date }.map { _, value in
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            return ChartDataPoint(
                label: formatter.string(from: value.date),
                value: value.total / Double(value.count),
                date: value.date
            )
        }
    }

    private func loadLast7DaysSteps() {
        let entries = fetchLast7Days()
        stepsData = entries.map { entry in
            ChartDataPoint(
                label: entry.shortDate,
                value: Double(entry.steps),
                date: entry.date ?? Date()
            )
        }
    }

    private func loadLast7DaysCalories() {
        let entries = fetchLast7Days()
        caloriesData = entries.map { entry in
            ChartDataPoint(
                label: entry.shortDate,
                value: Double(entry.calories),
                date: entry.date ?? Date()
            )
        }
    }

    private func fetchLast7Days() -> [DailyEntry] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", sevenDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: true)]

        return (try? viewContext.fetch(request)) ?? []
    }

    private func loadMonthlySummary() {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", startOfMonth as NSDate)

        guard let entries = try? viewContext.fetch(request), !entries.isEmpty else {
            monthlySummary = nil
            return
        }

        let totalSteps = entries.reduce(0) { $0 + Int($1.steps) }
        let totalCalories = entries.reduce(0) { $0 + Int($1.calories) }
        let trainingDays = entries.filter { $0.strengthTraining }.count

        monthlySummary = MonthlySummary(
            avgSteps: totalSteps / entries.count,
            avgCalories: totalCalories / entries.count,
            trainingDays: trainingDays,
            totalDays: entries.count
        )
    }

    private func loadMilestones() {
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)]
        request.predicate = NSPredicate(format: "weight > 0")
        request.fetchLimit = 1

        let currentWeight = (try? viewContext.fetch(request).first?.weight) ?? startWeight
        weightMilestones = MotivationEngine.weightMilestones(startWeight: startWeight, currentWeight: currentWeight)

        let streak = UserDefaults.standard.integer(forKey: "currentStreak")
        streakMilestones = MotivationEngine.streakMilestones(streak: streak)
    }
}
