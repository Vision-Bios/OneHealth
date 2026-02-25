import Foundation
import Combine

enum TimelineKind: String, Codable {
    case vaccine
    case diagnostic
    case medication
}

struct TimelineItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let date: Date
    let region: BodyRegion
    let kind: TimelineKind
}

final class TimelineViewModel: ObservableObject {
    @Published private(set) var items: [TimelineItem] = []

    let targetCount: Int = 30

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(items.count) / Double(targetCount), 1.0)
    }

    var progressLabel: String {
        "\(items.count) of \(targetCount) records added"
    }

    var rewards: [Reward] {
        let milestones: [(Int, String, String)] = [
            (1, "First Step", "You added your first record."),
            (5, "Momentum", "Five records collected."),
            (10, "Builder", "Ten records added."),
            (25, "Archivist", "Twenty-five records secured."),
            (50, "Lifelong", "Fifty records preserved.")
        ]

        return milestones.map { threshold, title, message in
            Reward(
                title: title,
                threshold: threshold,
                message: message,
                isUnlocked: items.count >= threshold
            )
        }
    }

    var nextRewardLabel: String {
        if let next = rewards.first(where: { !$0.isUnlocked }) {
            return "Next reward at \(next.threshold) records"
        }
        return "All rewards unlocked"
    }

    init() {
        load()
    }

    func load() {
        let vaccines: [VaccineRecord] = LocalStore.load("vaccines.json", as: [VaccineRecord].self) ?? []
        let diagnostics: [DiagnosticResult] = LocalStore.load("diagnostics.json", as: [DiagnosticResult].self) ?? []
        let medications: [MedicationRecord] = LocalStore.load("medications.json", as: [MedicationRecord].self) ?? []

        let vaccineItems = vaccines.map {
            TimelineItem(
                id: $0.id,
                title: $0.name,
                subtitle: "Vaccine • \($0.provider)",
                date: $0.date,
                region: $0.region,
                kind: .vaccine
            )
        }

        let diagnosticItems = diagnostics.map {
            TimelineItem(
                id: $0.id,
                title: $0.testName,
                subtitle: "Diagnostic • \($0.resultSummary)",
                date: $0.date,
                region: $0.region,
                kind: .diagnostic
            )
        }

        let medicationItems = medications.map {
            TimelineItem(
                id: $0.id,
                title: $0.name,
                subtitle: "\( $0.kind.displayName ) • \($0.sideEffects)",
                date: $0.date,
                region: $0.region,
                kind: .medication
            )
        }

        items = (vaccineItems + diagnosticItems + medicationItems).sorted { $0.date > $1.date }
    }
}
