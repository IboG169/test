import Foundation
import CoreData

extension DailyEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyEntry> {
        return NSFetchRequest<DailyEntry>(entityName: "DailyEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var steps: Int32
    @NSManaged public var calories: Int32
    @NSManaged public var weight: Double
    @NSManaged public var strengthTraining: Bool
    @NSManaged public var mood: Int16
    @NSManaged public var journalEntry: String?

    var moodEmoji: String {
        switch mood {
        case 0: return "\u{1F61E}"  // disappointed
        case 1: return "\u{1F610}"  // neutral
        case 2: return "\u{1F642}"  // slightly smiling
        case 3: return "\u{1F4AA}"  // flexed biceps
        case 4: return "\u{1F525}"  // fire
        default: return "\u{1F610}"
        }
    }

    var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    var shortDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: date)
    }

    var journalSnippet: String {
        guard let entry = journalEntry, !entry.isEmpty else { return "" }
        if entry.count <= 60 { return entry }
        return String(entry.prefix(60)) + "..."
    }
}

extension DailyEntry: Identifiable {}
