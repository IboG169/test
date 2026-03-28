import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(context: viewContext)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CheckInView(context: viewContext)
                .tabItem {
                    Label("Eintrag", systemImage: "plus.circle.fill")
                }
                .tag(1)

            YallaFitProgressView(context: viewContext)
                .tabItem {
                    Label("Fortschritt", systemImage: "chart.bar.fill")
                }
                .tag(2)

            HistoryView(context: viewContext)
                .tabItem {
                    Label("Verlauf", systemImage: "clock.fill")
                }
                .tag(3)

            SettingsView(context: viewContext)
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color(red: 0, green: 122.0/255.0, blue: 255.0/255.0))
    }
}
