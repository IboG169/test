import SwiftUI
import CoreData

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var expandedEntryID: UUID?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Verlauf")
            .onAppear { viewModel.loadEntries() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Theme.textSecondary.opacity(0.5))
            Text("Noch keine Eintraege")
                .font(.title3)
                .foregroundColor(Theme.textSecondary)
            Text("Starte deinen ersten Tageseintrag!")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.entries) { entry in
                    entryCard(entry)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if expandedEntryID == entry.id {
                                    expandedEntryID = nil
                                } else {
                                    expandedEntryID = entry.id
                                }
                            }
                        }
                }
            }
            .padding()
        }
    }

    private func entryCard(_ entry: DailyEntry) -> some View {
        let isExpanded = expandedEntryID == entry.id

        return VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Text(entry.formattedDate)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text(entry.moodEmoji)
                    .font(.title2)

                if entry.weight > 0 {
                    Text(String(format: "%.1f kg", entry.weight).replacingOccurrences(of: ".", with: ","))
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.accentBlue)
                }
            }

            // Stats row
            HStack(spacing: 16) {
                Label("\(entry.steps)", systemImage: "figure.walk")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                Label("\(entry.calories) kcal", systemImage: "flame.fill")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                if entry.strengthTraining {
                    Label("Training", systemImage: "dumbbell.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            // Journal snippet or full
            if let journal = entry.journalEntry, !journal.isEmpty {
                if isExpanded {
                    Divider()
                    Text(journal)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                        .transition(.opacity)
                } else if !entry.journalSnippet.isEmpty {
                    Text(entry.journalSnippet)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            if isExpanded && entry.journalEntry != nil {
                HStack {
                    Spacer()
                    Text("Tippe zum Schliessen")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                }
            }
        }
        .cardStyle()
    }
}
