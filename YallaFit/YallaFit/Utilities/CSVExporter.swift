import Foundation
import CoreData

struct CSVExporter {
    static func exportEntries(context: NSManagedObjectContext) -> URL? {
        let fetchRequest: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: true)]

        guard let entries = try? context.fetch(fetchRequest) else { return nil }

        var csv = "Datum;Gewicht (kg);Schritte;Kalorien;Krafttraining;Stimmung;Tagebuch\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        for entry in entries {
            let date = entry.date.map { dateFormatter.string(from: $0) } ?? ""
            let weight = String(format: "%.1f", entry.weight).replacingOccurrences(of: ".", with: ",")
            let steps = "\(entry.steps)"
            let calories = "\(entry.calories)"
            let strength = entry.strengthTraining ? "Ja" : "Nein"
            let mood = entry.moodEmoji
            let journal = (entry.journalEntry ?? "")
                .replacingOccurrences(of: ";", with: ",")
                .replacingOccurrences(of: "\n", with: " ")

            csv += "\(date);\(weight);\(steps);\(calories);\(strength);\(mood);\(journal)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("YallaFit_Export_\(dateFormatter.string(from: Date())).csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
