import Foundation

enum HealthQueryService {
    static func answer(for query: String) -> String {
        let normalized = query.lowercased()

        if normalized.contains("vaccine") {
            return vaccinesAnswer(for: normalized)
        }

        if normalized.contains("diagnostic") || normalized.contains("test") || normalized.contains("result") {
            return diagnosticsAnswer(for: normalized)
        }

        if normalized.contains("med") || normalized.contains("supplement") || normalized.contains("medication") {
            return medicationsAnswer()
        }

        return "I can help with vaccines, diagnostics, or medications. Try asking about a vaccine name or a test result."
    }

    private static func vaccinesAnswer(for query: String) -> String {
        let records: [VaccineRecord] = LocalStore.load("vaccines.json", as: [VaccineRecord].self) ?? []
        guard records.isEmpty == false else {
            return "I don't see any vaccines yet."
        }

        if let match = matchName(in: records.map(\.name), query: query) {
            let filtered = records.filter { $0.name.lowercased().contains(match) }
            let details = filtered.sorted(by: { $0.date > $1.date })
            let lines = details.map { record in
                let dateText = makeDateFormatter().string(from: record.date)
                return "\(record.name) — \(dateText) (\(record.provider))"
            }
            return "Vaccine records for \(match): " + lines.joined(separator: " | ")
        }

        let latest = records.sorted(by: { $0.date > $1.date }).prefix(5)
        let list = latest.map { record in
            let dateText = makeDateFormatter().string(from: record.date)
            return "\(record.name) on \(dateText)"
        }
        return "Here are your most recent vaccines: " + list.joined(separator: ", ") + "."
    }

    private static func diagnosticsAnswer(for query: String) -> String {
        let records: [DiagnosticResult] = LocalStore.load("diagnostics.json", as: [DiagnosticResult].self) ?? []
        guard records.isEmpty == false else {
            return "I don't see any diagnostic tests yet."
        }

        if let match = matchName(in: records.map(\.testName), query: query) {
            let filtered = records.filter { $0.testName.lowercased().contains(match) }
            let details = filtered.sorted(by: { $0.date > $1.date })
            let lines = details.map { record in
                let dateText = makeDateFormatter().string(from: record.date)
                return "\(record.testName) — \(record.resultSummary) on \(dateText)"
            }
            return "Diagnostic results for \(match): " + lines.joined(separator: " | ")
        }

        let latest = records.sorted(by: { $0.date > $1.date }).prefix(5)
        let list = latest.map { record in
            let dateText = makeDateFormatter().string(from: record.date)
            return "\(record.testName) (\(record.resultSummary)) on \(dateText)"
        }
        return "Here are your most recent diagnostics: " + list.joined(separator: ", ") + "."
    }

    private static func medicationsAnswer() -> String {
        let records: [MedicationRecord] = LocalStore.load("medications.json", as: [MedicationRecord].self) ?? []
        guard records.isEmpty == false else {
            return "I don't see any medications or supplements yet."
        }

        let latest = records.sorted(by: { $0.date > $1.date }).prefix(5)
        let list = latest.map { record in
            let dateText = makeDateFormatter().string(from: record.date)
            return "\(record.name) (\(record.kind.displayName)) on \(dateText)"
        }
        return "Here are your most recent medications and supplements: " + list.joined(separator: ", ") + "."
    }

    private static func matchName(in names: [String], query: String) -> String? {
        let lowered = query.lowercased()
        for name in names {
            let token = name.lowercased()
            if lowered.contains(token) {
                return token
            }
        }
        return nil
    }

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
