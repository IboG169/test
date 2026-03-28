import Foundation

struct MotivationEngine {
    static let quotes: [String] = [
        "Jeder Schritt bringt dich deinem Ziel naeher. Yalla!",
        "Disziplin ist staerker als Motivation. Bleib dran!",
        "Der Koerper erreicht, was der Geist glaubt.",
        "Kleine Fortschritte sind immer noch Fortschritte.",
        "Wer Geduld hat, wird belohnt. Vertraue dem Prozess.",
        "Du bist staerker als du denkst. Mashallah!",
        "Heute ist ein neuer Tag, eine neue Chance. Yalla!",
        "Gesundheit ist der groesste Reichtum.",
        "Sei geduldig mit dir selbst. Veraenderung braucht Zeit.",
        "Bismillah - mit jedem Training wirst du staerker.",
        "Dein Koerper ist eine Amanah. Pflege ihn gut.",
        "Erfolg kommt nicht ueber Nacht, aber er kommt. Inshallah!",
        "Wer frueh aufsteht, dem gehoert die Welt.",
        "Jeder Tag ist eine neue Gelegenheit, besser zu werden.",
        "Aufgeben ist keine Option. Du schaffst das!",
        "Die beste Zeit anzufangen war gestern. Die zweitbeste ist jetzt.",
        "Stark ist nicht, wer nie faellt. Stark ist, wer immer wieder aufsteht.",
        "Vertraue auf Allah und binde dein Kamel an.",
        "Dein Schweis von heute ist dein Stolz von morgen.",
        "Mashallah, du bist auf dem richtigen Weg!",
        "Sabr - Geduld fuehrt zum Erfolg.",
        "Ein gesunder Koerper traegt einen gesunden Geist.",
        "Du kaempfst nicht gegen andere, sondern fuer dich selbst.",
        "Alhamdulillah fuer jeden Tag, an dem du dich bewegst.",
        "Ibrahim, du bist ein Kaempfer. Weiter so!",
        "Tawakkul - Vertraue auf den Plan und gib dein Bestes.",
        "Wer sein Ziel kennt, findet den Weg.",
        "Die Reise von tausend Meilen beginnt mit einem Schritt.",
        "Heute Schweis, morgen Stolz. Yalla Ibrahim!",
        "Deine Gesundheit ist dein wertvollstes Gut. Schuetze sie.",
    ]

    static func quoteOfTheDay() -> String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }

    static func streakMessage(streak: Int) -> String? {
        guard streak >= 3 else { return nil }
        switch streak {
        case 3...6: return "\u{1F525} \(streak) Tage Streak! Weiter so!"
        case 7...13: return "\u{1F525}\u{1F525} \(streak) Tage! Eine ganze Woche! Mashallah!"
        case 14...29: return "\u{1F525}\u{1F525}\u{1F525} \(streak) Tage Streak! Unaufhaltbar!"
        default: return "\u{1F525}\u{1F525}\u{1F525}\u{1F525} \(streak) Tage! Du bist eine Legende, Ibrahim!"
        }
    }

    static func calorieMessage(calories: Int, goal: Int) -> String? {
        guard calories > goal else { return nil }
        let over = calories - goal
        if over < 200 {
            return "Nur \(over) kcal ueber dem Ziel - morgen wird's besser! Du schaffst das \u{1F4AA}"
        } else {
            return "Heute etwas mehr gegessen - kein Problem! Jeder Tag ist ein neuer Start \u{1F642}"
        }
    }

    static func stepsMessage(steps: Int, goal: Int) -> String? {
        guard steps >= goal else { return nil }
        return "Mashallah! Ueber \(goal >= 10000 ? "10.000" : "\(goal)") Schritte! \u{1F389}"
    }

    static func phase1Countdown() -> Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 26
        guard let targetDate = calendar.date(from: components) else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: targetDate).day ?? 0
        return max(0, days)
    }

    static func weightMilestones(startWeight: Double, currentWeight: Double) -> [Milestone] {
        var milestones: [Milestone] = []
        let lost = startWeight - currentWeight

        let thresholds: [(kg: Double, label: String, icon: String)] = [
            (2, "2 kg geschafft!", "\u{2B50}"),
            (5, "5 kg geschafft!", "\u{1F3C5}"),
            (10, "10 kg geschafft!", "\u{1F3C6}"),
            (15, "15 kg geschafft!", "\u{1F48E}"),
            (18.5, "Phase 1 Ziel erreicht!", "\u{1F451}"),
        ]

        for t in thresholds {
            milestones.append(Milestone(
                label: t.label,
                icon: t.icon,
                achieved: lost >= t.kg,
                requiredKg: t.kg
            ))
        }
        return milestones
    }

    static func streakMilestones(streak: Int) -> [Milestone] {
        let thresholds: [(days: Int, label: String, icon: String)] = [
            (3, "3 Tage Streak", "\u{1F525}"),
            (7, "1 Woche Streak", "\u{1F31F}"),
            (14, "2 Wochen Streak", "\u{26A1}"),
            (30, "1 Monat Streak", "\u{1F680}"),
            (60, "2 Monate Streak", "\u{1F47E}"),
            (90, "3 Monate Streak", "\u{1F451}"),
        ]

        return thresholds.map { t in
            Milestone(label: t.label, icon: t.icon, achieved: streak >= t.days, requiredKg: Double(t.days))
        }
    }
}

struct Milestone: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let achieved: Bool
    let requiredKg: Double
}
