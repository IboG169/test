import Foundation
import CoreData
import SwiftUI

class DashboardViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var currentWeight: String = ""
    @Published var todayEntry: DailyEntry?
    @Published var streak: Int = 0
    @Published var quote: String = ""
    @Published var showConfetti = false

    var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "Ibrahim"
    }

    var startWeight: Double {
        UserDefaults.standard.double(forKey: "startWeight").isZero ? 123.5 : UserDefaults.standard.double(forKey: "startWeight")
    }

    var goalWeight: Double {
        UserDefaults.standard.double(forKey: "goalWeight").isZero ? 105.0 : UserDefaults.standard.double(forKey: "goalWeight")
    }

    var stepGoal: Int {
        let goal = UserDefaults.standard.integer(forKey: "stepGoal")
        return goal == 0 ? 10000 : goal
    }

    var calorieGoal: Int {
        let goal = UserDefaults.standard.integer(forKey: "calorieGoal")
        return goal == 0 ? 2400 : goal
    }

    var latestWeight: Double {
        if let entry = todayEntry, entry.weight > 0 { return entry.weight }
        return fetchLatestWeight() ?? startWeight
    }

    var weightProgress: Double {
        let totalToLose = startWeight - goalWeight
        guard totalToLose > 0 else { return 0 }
        let lost = startWeight - latestWeight
        return min(max(lost / totalToLose, 0), 1.0)
    }

    var weightLost: Double {
        return startWeight - latestWeight
    }

    var phase1Countdown: Int {
        MotivationEngine.phase1Countdown()
    }

    var streakMessage: String? {
        MotivationEngine.streakMessage(streak: streak)
    }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.quote = MotivationEngine.quoteOfTheDay()
        loadData()
    }

    func loadData() {
        loadTodayEntry()
        calculateStreak()
        quote = MotivationEngine.quoteOfTheDay()

        if let entry = todayEntry, entry.steps >= Int32(stepGoal) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showConfetti = true
            }
        }
    }

    private func loadTodayEntry() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1

        todayEntry = try? viewContext.fetch(request).first
    }

    private func fetchLatestWeight() -> Double? {
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)]
        request.predicate = NSPredicate(format: "weight > 0")
        request.fetchLimit = 1

        return try? viewContext.fetch(request).first?.weight
    }

    func calculateStreak() {
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)]

        guard let entries = try? viewContext.fetch(request) else {
            streak = 0
            return
        }

        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for entry in entries {
            guard let entryDate = entry.date else { continue }
            let entryDay = calendar.startOfDay(for: entryDate)

            if entryDay == checkDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if entryDay < checkDate {
                break
            }
        }

        streak = currentStreak
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
    }

    func saveWeight(_ weightString: String) {
        let cleaned = weightString.replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(cleaned), weight > 0 else { return }

        if let entry = todayEntry {
            entry.weight = weight
        } else {
            let entry = DailyEntry(context: viewContext)
            entry.id = UUID()
            entry.date = Date()
            entry.weight = weight
            todayEntry = entry
        }

        try? viewContext.save()
        objectWillChange.send()
    }
}
