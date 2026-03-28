import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var notificationManager = NotificationManager.shared

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section("Profil") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Name", text: $viewModel.userName)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Weight Goals Section
                Section("Gewichtsziele") {
                    HStack {
                        Text("Startgewicht (kg)")
                        Spacer()
                        TextField("123,5", text: $viewModel.startWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Zielgewicht Phase 1 (kg)")
                        Spacer()
                        TextField("105,0", text: $viewModel.goalWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                // Daily Goals Section
                Section("Tagesziele") {
                    HStack {
                        Text("Schritte")
                        Spacer()
                        TextField("10.000", text: $viewModel.stepGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Kalorien (kcal)")
                        Spacer()
                        TextField("2.400", text: $viewModel.calorieGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                // Notifications Section
                Section("Benachrichtigungen") {
                    if !notificationManager.isAuthorized {
                        Button("Benachrichtigungen aktivieren") {
                            notificationManager.requestAuthorization()
                        }
                        .foregroundColor(Theme.accentBlue)
                    } else {
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.orange)
                            Text("Morgens")
                            Spacer()
                            Picker("Stunde", selection: $viewModel.morningHour) {
                                ForEach(5..<12) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            Text(":")
                            Picker("Minute", selection: $viewModel.morningMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(.purple)
                            Text("Abends")
                            Spacer()
                            Picker("Stunde", selection: $viewModel.eveningHour) {
                                ForEach(18..<24) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            Text(":")
                            Picker("Minute", selection: $viewModel.eveningMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                // Export Section
                Section("Daten") {
                    Button(action: { viewModel.exportCSV() }) {
                        Label("Als CSV exportieren", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(Theme.accentBlue)
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        viewModel.showResetConfirmation = true
                    } label: {
                        Label("Alle Daten loeschen", systemImage: "trash.fill")
                    }
                } footer: {
                    Text("Dies loescht alle Eintraege und setzt die Einstellungen zurueck.")
                }

                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(Theme.textSecondary)
                    }
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("YallaFit")
                                .font(.headline)
                                .foregroundColor(Theme.accentBlue)
                            Text("Yalla!")
                                .font(.title2.bold())
                                .foregroundColor(Theme.gold)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Alle Daten loeschen?", isPresented: $viewModel.showResetConfirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Loeschen", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("Diese Aktion kann nicht rueckgaengig gemacht werden.")
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .onAppear {
                notificationManager.checkAuthorizationStatus()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
