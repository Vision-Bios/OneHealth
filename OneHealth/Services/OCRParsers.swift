import Foundation

struct VaccineOCRDraft: Identifiable {
    let id = UUID()
    var name: String
    var date: Date?
    var notes: String
}

struct DiagnosticOCRDraft: Identifiable {
    let id = UUID()
    var testName: String
    var resultSummary: String
    var date: Date?
    var notes: String
}

struct MedicationOCRDraft: Identifiable {
    let id = UUID()
    var name: String
    var kind: MedicationKind
    var date: Date?
    var sideEffects: String
    var notes: String
}

enum OCRParsers {
    static func parseVaccineEntries(text: String) -> [VaccineOCRDraft] {
        let lines = normalize(text)
        var currentVaccine = detectVaccineHeading(in: lines.joined(separator: " ")) ?? ""
        var drafts: [VaccineOCRDraft] = []
        var seenDates = Set<TimeInterval>()

        for line in lines {
            if isHeaderNoise(line) {
                continue
            }

            if let detected = detectVaccineHeading(in: line) {
                currentVaccine = detected
                continue
            }

            let dates = dates(in: line)
            if dates.isEmpty { continue }

            if currentVaccine.isEmpty {
                currentVaccine = firstNonDateLine(in: lines) ?? "Unknown vaccine"
            }

            let dose = doseNumber(in: line)
            let subtype = vaccineSubtype(in: line)
            for date in dates {
                let key = date.timeIntervalSince1970
                if seenDates.contains(key) { continue }
                seenDates.insert(key)
                var noteParts: [String] = []
                if let dose {
                    noteParts.append("Dose \(dose)")
                }
                if let subtype {
                    noteParts.append(subtype)
                }
                if noteParts.isEmpty {
                    noteParts.append(line)
                } else {
                    noteParts.append(line)
                }
                let note = noteParts.joined(separator: " • ")
                drafts.append(VaccineOCRDraft(name: currentVaccine, date: date, notes: note))
            }
        }

        if drafts.isEmpty {
            let notes = lines.joined(separator: " ")
            drafts.append(VaccineOCRDraft(name: currentVaccine.isEmpty ? "Unknown vaccine" : currentVaccine, date: firstDate(in: lines), notes: notes))
        }

        return drafts
    }

    static func parseDiagnosticEntries(text: String) -> [DiagnosticOCRDraft] {
        let lines = normalize(text)
        var drafts: [DiagnosticOCRDraft] = []
        let testName = firstNonDateLine(in: lines) ?? "Unknown test"
        let result = firstResult(in: lines) ?? "Result not specified"
        let datesFound = lines.flatMap { dates(in: $0) }
        let uniqueDates = Array(Set(datesFound.map { $0.timeIntervalSince1970 })).map { Date(timeIntervalSince1970: $0) }

        if uniqueDates.isEmpty {
            drafts.append(DiagnosticOCRDraft(testName: testName, resultSummary: result, date: firstDate(in: lines), notes: lines.joined(separator: " ")))
            return drafts
        }

        for date in uniqueDates {
            drafts.append(DiagnosticOCRDraft(testName: testName, resultSummary: result, date: date, notes: lines.joined(separator: " ")))
        }
        return drafts
    }

    static func parseMedicationEntries(text: String) -> [MedicationOCRDraft] {
        let lines = normalize(text)
        let name = firstNonDateLine(in: lines) ?? "Unknown medication"
        let kind = detectMedicationKind(in: lines)
        let sideEffects = detectSideEffects(in: lines) ?? "None"
        let notes = lines.joined(separator: " ")
        let datesFound = lines.flatMap { dates(in: $0) }
        let uniqueDates = Array(Set(datesFound.map { $0.timeIntervalSince1970 })).map { Date(timeIntervalSince1970: $0) }

        if uniqueDates.isEmpty {
            return [MedicationOCRDraft(name: name, kind: kind, date: firstDate(in: lines), sideEffects: sideEffects, notes: notes)]
        }

        return uniqueDates.map { date in
            MedicationOCRDraft(name: name, kind: kind, date: date, sideEffects: sideEffects, notes: notes)
        }
    }

    static func parseDiagnostic(text: String) -> DiagnosticOCRDraft {
        let lines = normalize(text)
        let date = firstDate(in: lines)
        let testName = firstNonDateLine(in: lines) ?? "Unknown test"
        let result = firstResult(in: lines) ?? "Result not specified"
        let notes = lines.joined(separator: " ")
        return DiagnosticOCRDraft(testName: testName, resultSummary: result, date: date, notes: notes)
    }

    static func parseMedication(text: String) -> MedicationOCRDraft {
        let lines = normalize(text)
        let date = firstDate(in: lines)
        let name = firstNonDateLine(in: lines) ?? "Unknown medication"
        let kind = detectMedicationKind(in: lines)
        let sideEffects = detectSideEffects(in: lines) ?? "None"
        let notes = lines.joined(separator: " ")
        return MedicationOCRDraft(name: name, kind: kind, date: date, sideEffects: sideEffects, notes: notes)
    }

    private static func normalize(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private static func firstNonDateLine(in lines: [String]) -> String? {
        for line in lines {
            if parseDate(line) == nil {
                return line
            }
        }
        return nil
    }

    private static func firstDate(in lines: [String]) -> Date? {
        for line in lines {
            if let date = parseDate(line) {
                return date
            }
        }
        return nil
    }

    private static func firstResult(in lines: [String]) -> String? {
        let keywords = ["negative", "positive", "reactive", "non-reactive", "normal", "abnormal"]
        for line in lines {
            let lowered = line.lowercased()
            if let keyword = keywords.first(where: { lowered.contains($0) }) {
                return keyword.capitalized
            }
        }
        return nil
    }

    private static func detectMedicationKind(in lines: [String]) -> MedicationKind {
        let lowered = lines.joined(separator: " ").lowercased()
        if lowered.contains("supplement") || lowered.contains("vitamin") || lowered.contains("omega") {
            return .supplement
        }
        return .medication
    }

    private static func detectSideEffects(in lines: [String]) -> String? {
        let lowered = lines.joined(separator: " ").lowercased()
        if lowered.contains("side effect") || lowered.contains("side-effects") {
            return lines.first { $0.lowercased().contains("side") }
        }
        return nil
    }

    private static func dates(in text: String) -> [Date] {
        let normalized = text
            .replacingOccurrences(of: "-", with: "/")
            .replacingOccurrences(of: ".", with: "/")
        var results: [Date] = []

        let numericPattern = #"\b(\d{1,2}/\d{1,2}/\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let r = Range(match.range(at: 1), in: normalized) else { continue }
                let token = String(normalized[r])
                if let date = parseDateString(token) {
                    results.append(date)
                }
            }
        }

        let monthPattern = #"\b([A-Za-z]{3,9})\s+(\d{1,2})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: monthPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mRange = Range(match.range(at: 1), in: normalized),
                      let dRange = Range(match.range(at: 2), in: normalized),
                      let yRange = Range(match.range(at: 3), in: normalized) else { continue }
                let month = String(normalized[mRange])
                let day = String(normalized[dRange])
                let year = String(normalized[yRange])
                if let date = parseMonthDate(month: month, day: day, year: year) {
                    results.append(date)
                }
            }
        }

        return results
    }

    private static func parseDate(_ text: String) -> Date? {
        let cleaned = text
            .replacingOccurrences(of: "-", with: "/")
            .replacingOccurrences(of: ".", with: "/")
        let components = cleaned.split(whereSeparator: { $0 == " " || $0 == "\t" })
        for part in components {
            if let date = parseDateString(String(part)) {
                return date
            }
        }
        return nil
    }

    private static func parseDateString(_ value: String) -> Date? {
        let patterns = ["M/d/yy", "M/d/yyyy", "MM/dd/yy", "MM/dd/yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for pattern in patterns {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private static func parseMonthDate(month: String, day: String, year: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d yyyy"

        let cleanedMonth = month.replacingOccurrences(of: ".", with: "")
        let value = "\(cleanedMonth) \(day) \(year)"
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.dateFormat = "MMMM d yyyy"
        return formatter.date(from: value)
    }

    private static func doseNumber(in text: String) -> Int? {
        let pattern = #"\b([1-6])\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let r = Range(match.range(at: 1), in: text) else { return nil }
        return Int(text[r])
    }

    private static func detectVaccineHeading(in line: String) -> String? {
        let lowered = line.lowercased()
        if lowered.contains("hepatitis b") {
            return "Hepatitis B"
        }
        if lowered.contains("varicella") || lowered.contains("chickenpox") {
            return "Varicella (Chickenpox)"
        }
        if lowered.contains("rotavirus") {
            return "Rotavirus"
        }
        if lowered.contains("diphtheria") || lowered.contains("tetanus") || lowered.contains("pertussis") {
            return "Diphtheria Tetanus Pertussis (DTaP)"
        }
        if lowered.contains("haemophilus") || lowered.contains("hib") {
            return "Haemophilus influenzae type b (Hib)"
        }
        if lowered.contains("polio") {
            return "Polio"
        }
        if lowered.contains("mmr") {
            return "MMR"
        }
        if lowered.contains("influenza") {
            return "Influenza"
        }
        if lowered.contains("hpv") {
            return "HPV"
        }
        return nil
    }

    private static func vaccineSubtype(in line: String) -> String? {
        let lowered = line.lowercased()
        if lowered.contains("dtap") { return "DTaP" }
        if lowered.contains("tdap") { return "Tdap" }
        if lowered.contains("dt/dt") { return "DT" }
        return nil
    }

    private static func isHeaderNoise(_ line: String) -> Bool {
        let lowered = line.lowercased()
        let noise = [
            "vaccine",
            "date given",
            "doctor office",
            "clinic",
            "next dose",
            "copied from medical records"
        ]
        return noise.contains { lowered.contains($0) }
    }
}
