import Foundation
import CoreData

class CheckInViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var steps: String = ""
    @Published var calories: String = ""
    @Published var strengthTraining: Bool = false
    @Published var selectedMood: Int = 2
    @Published var journalEntry: String = ""
    @Published var weight: String = ""
    @Published var saved = false
    @Published var showConfetti = false
    @Published var stepsOverGoal = false
    @Published var caloriesOverGoal = false
    @Published var calorieMessage: String?

    var stepGoal: Int {
        let goal = UserDefaults.standard.integer(forKey: "stepGoal")
        return goal == 0 ? 10000 : goal
    }

    var calorieGoal: Int {
        let goal = UserDefaults.standard.integer(forKey: "calorieGoal")
        return goal == 0 ? 2400 : goal
    }

    var stepsInt: Int { Int(steps) ?? 0 }
    var caloriesInt: Int { Int(calories) ?? 0 }

    var stepsProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(Double(stepsInt) / Double(stepGoal), 1.0)
    }

    var caloriesProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(Double(caloriesInt) / Double(calorieGoal), 1.0)
    }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadExistingEntry()
    }

    private func loadExistingEntry() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1

        if let entry = try? viewContext.fetch(request).first {
            steps = entry.steps > 0 ? "\(entry.steps)" : ""
            calories = entry.calories > 0 ? "\(entry.calories)" : ""
            strengthTraining = entry.strengthTraining
            selectedMood = Int(entry.mood)
            journalEntry = entry.journalEntry ?? ""
            weight = entry.weight > 0 ? String(format: "%.1f", entry.weight).replacingOccurrences(of: ".", with: ",") : ""
        }
    }

    func saveEntry() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1

        let entry: DailyEntry
        if let existing = try? viewContext.fetch(request).first {
            entry = existing
        } else {
            entry = DailyEntry(context: viewContext)
            entry.id = UUID()
            entry.date = Date()
        }

        entry.steps = Int32(stepsInt)
        entry.calories = Int32(caloriesInt)
        entry.strengthTraining = strengthTraining
        entry.mood = Int16(selectedMood)
        entry.journalEntry = journalEntry.isEmpty ? nil : journalEntry

        let weightCleaned = weight.replacingOccurrences(of: ",", with: ".")
        if let w = Double(weightCleaned), w > 0 {
            entry.weight = w
        }

        try? viewContext.save()

        // Check achievements
        if stepsInt >= stepGoal {
            showConfetti = true
            stepsOverGoal = true
        }

        if caloriesInt > calorieGoal {
            caloriesOverGoal = true
            calorieMessage = MotivationEngine.calorieMessage(calories: caloriesInt, goal: calorieGoal)
        }

        saved = true
    }
}
