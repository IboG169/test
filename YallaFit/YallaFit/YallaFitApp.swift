import SwiftUI

@main
struct YallaFitApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Initialize defaults
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
        if defaults.string(forKey: "userName") == nil {
            defaults.set("Ibrahim", forKey: "userName")
        }
        if defaults.integer(forKey: "morningNotificationHour") == 0 {
            defaults.set(7, forKey: "morningNotificationHour")
        }
        if defaults.integer(forKey: "eveningNotificationHour") == 0 {
            defaults.set(21, forKey: "eveningNotificationHour")
        }

        // Set dark mode appearance
        configureAppearance()

        // Request notification permission
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
