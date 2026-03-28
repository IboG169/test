import Foundation
import CoreData

class SettingsViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var startWeight: String {
        didSet {
            let cleaned = startWeight.replacingOccurrences(of: ",", with: ".")
            if let value = Double(cleaned) {
                UserDefaults.standard.set(value, forKey: "startWeight")
            }
        }
    }
    @Published var goalWeight: String {
        didSet {
            let cleaned = goalWeight.replacingOccurrences(of: ",", with: ".")
            if let value = Double(cleaned) {
                UserDefaults.standard.set(value, forKey: "goalWeight")
            }
        }
    }
    @Published var stepGoal: String {
        didSet {
            if let value = Int(stepGoal.replacingOccurrences(of: ".", with: "")) {
                UserDefaults.standard.set(value, forKey: "stepGoal")
            }
        }
    }
    @Published var calorieGoal: String {
        didSet {
            if let value = Int(calorieGoal.replacingOccurrences(of: ".", with: "")) {
                UserDefaults.standard.set(value, forKey: "calorieGoal")
            }
        }
    }
    @Published var morningHour: Int {
        didSet {
            UserDefaults.standard.set(morningHour, forKey: "morningNotificationHour")
            NotificationManager.shared.scheduleNotifications()
        }
    }
    @Published var morningMinute: Int {
        didSet {
            UserDefaults.standard.set(morningMinute, forKey: "morningNotificationMinute")
            NotificationManager.shared.scheduleNotifications()
        }
    }
    @Published var eveningHour: Int {
        didSet {
            UserDefaults.standard.set(eveningHour, forKey: "eveningNotificationHour")
            NotificationManager.shared.scheduleNotifications()
        }
    }
    @Published var eveningMinute: Int {
        didSet {
            UserDefaults.standard.set(eveningMinute, forKey: "eveningNotificationMinute")
            NotificationManager.shared.scheduleNotifications()
        }
    }

    @Published var showResetConfirmation = false
    @Published var showExportSheet = false
    @Published var exportURL: URL?

    init(context: NSManagedObjectContext) {
        self.viewContext = context

        let defaults = UserDefaults.standard
        self.userName = defaults.string(forKey: "userName") ?? "Ibrahim"

        let sw = defaults.double(forKey: "startWeight")
        self.startWeight = sw > 0 ? String(format: "%.1f", sw).replacingOccurrences(of: ".", with: ",") : "123,5"

        let gw = defaults.double(forKey: "goalWeight")
        self.goalWeight = gw > 0 ? String(format: "%.1f", gw).replacingOccurrences(of: ".", with: ",") : "105,0"

        let sg = defaults.integer(forKey: "stepGoal")
        self.stepGoal = sg > 0 ? "10.000" : "10.000"

        let cg = defaults.integer(forKey: "calorieGoal")
        self.calorieGoal = cg > 0 ? "\(cg)" : "2.400"

        self.morningHour = defaults.integer(forKey: "morningNotificationHour")
        if morningHour == 0 { self.morningHour = 7 }
        self.morningMinute = defaults.integer(forKey: "morningNotificationMinute")

        self.eveningHour = defaults.integer(forKey: "eveningNotificationHour")
        if eveningHour == 0 { self.eveningHour = 21 }
        self.eveningMinute = defaults.integer(forKey: "eveningNotificationMinute")
    }

    func initializeDefaults() {
        let defaults = UserDefaults.standard
        if defaults.double(forKey: "startWeight") == 0 {
            defaults.set(123.5, forKey: "startWeight")
        }
        if defaults.double(forKey: "goalWeight") == 0 {
            defaults.set(105.0, forKey: "goalWeight")
        }
        if defaults.integer(forKey: "stepGoal") == 0 {
            defaults.set(10000, forKey: "stepGoal")
        }
        if defaults.integer(forKey: "calorieGoal") == 0 {
            defaults.set(2400, forKey: "calorieGoal")
        }
    }

    func resetAllData() {
        PersistenceController.shared.deleteAllData()

        let defaults = UserDefaults.standard
        let keys = ["userName", "startWeight", "goalWeight", "stepGoal", "calorieGoal",
                     "morningNotificationHour", "morningNotificationMinute",
                     "eveningNotificationHour", "eveningNotificationMinute", "currentStreak"]
        keys.forEach { defaults.removeObject(forKey: $0) }

        userName = "Ibrahim"
        startWeight = "123,5"
        goalWeight = "105,0"
        stepGoal = "10.000"
        calorieGoal = "2.400"
        morningHour = 7
        morningMinute = 0
        eveningHour = 21
        eveningMinute = 0
    }

    func exportCSV() {
        exportURL = CSVExporter.exportEntries(context: viewContext)
        if exportURL != nil {
            showExportSheet = true
        }
    }
}
