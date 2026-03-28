import Foundation
import CoreData

class HistoryViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var entries: [DailyEntry] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadEntries()
    }

    func loadEntries() {
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)]

        entries = (try? viewContext.fetch(request)) ?? []
    }
}
