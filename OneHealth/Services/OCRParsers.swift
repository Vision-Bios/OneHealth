import Foundation

struct VaccineOCRDraft: Identifiable {
    let id = UUID()
    var name: String
    var date: Date?
    var provider: String
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

            let matches = dateMatches(in: line)
            let dates = matches.map { $0.date }
            if dates.isEmpty { continue }

            let parsedName = extractVaccineName(from: line, matches: matches)
            if currentVaccine.isEmpty {
                currentVaccine = parsedName ?? firstNonDateLine(in: lines) ?? "Unknown vaccine"
            }
            let provider = extractProvider(from: line, matches: matches) ?? ""
            let cleanedLine = removeProvider(from: line, provider: provider)
            let cleanedNotes = removeRedundantVaccineInfo(from: cleanedLine, vaccineName: currentVaccine)

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
                let baseNotes = cleanedNotes.isEmpty ? cleanedLine : cleanedNotes
                if baseNotes.isEmpty == false {
                    noteParts.append(baseNotes)
                }
                let note = noteParts.joined(separator: " • ").trimmingCharacters(in: .whitespacesAndNewlines)
                drafts.append(VaccineOCRDraft(name: currentVaccine, date: date, provider: provider, notes: note))
            }
        }

        if drafts.isEmpty {
            let notes = lines.joined(separator: " ")
            let matches = dateMatches(in: notes)
            let provider = extractProvider(from: notes, matches: matches) ?? ""
            drafts.append(VaccineOCRDraft(
                name: currentVaccine.isEmpty ? "Unknown vaccine" : currentVaccine,
                date: firstDate(in: lines),
                provider: provider,
                notes: removeRedundantVaccineInfo(from: removeProvider(from: notes, provider: provider), vaccineName: currentVaccine)
            ))
        }

        return drafts
    }

    static func parseDiagnosticEntries(text: String) -> [DiagnosticOCRDraft] {
        let lines = normalize(text)
        var drafts: [DiagnosticOCRDraft] = []
        let fallbackName = firstNonDateLine(in: lines) ?? "Unknown test"
        let fallbackResult = extractResult(from: lines.joined(separator: " ")) ?? firstResult(in: lines) ?? "Result not specified"

        for line in lines {
            if isHeaderNoise(line) {
                continue
            }
            let matches = dateMatches(in: line)
            let dates = matches.map { $0.date }
            if dates.isEmpty { continue }

            let testName = extractTestName(from: line, matches: matches) ?? fallbackName
            let result = extractResult(from: line) ?? fallbackResult
            let provider = extractProvider(from: line, matches: matches) ?? ""
            let cleanedLine = removeProvider(from: line, provider: provider)
            let notes = appendProviderNote(base: cleanedLine, provider: provider)

            for date in dates {
                drafts.append(DiagnosticOCRDraft(testName: testName, resultSummary: result, date: date, notes: notes))
            }
        }

        if drafts.isEmpty {
            let notes = lines.joined(separator: " ")
            drafts.append(DiagnosticOCRDraft(testName: fallbackName, resultSummary: fallbackResult, date: firstDate(in: lines), notes: notes))
        }
        return drafts
    }

    static func parseMedicationEntries(text: String) -> [MedicationOCRDraft] {
        let lines = normalize(text)
        let fallbackName = firstNonDateLine(in: lines) ?? "Unknown medication"
        let kind = detectMedicationKind(in: lines)
        let fallbackSideEffects = detectSideEffects(in: lines) ?? "None"

        var drafts: [MedicationOCRDraft] = []
        for line in lines {
            if isHeaderNoise(line) {
                continue
            }
            let matches = dateMatches(in: line)
            let dates = matches.map { $0.date }
            if dates.isEmpty { continue }

            let name = extractMedicationName(from: line, matches: matches) ?? fallbackName
            let sideEffects = extractSideEffects(from: line) ?? fallbackSideEffects
            let cleanedLine = removeSideEffects(from: line, sideEffects: sideEffects)
            let notes = cleanedLine.isEmpty ? line : cleanedLine

            for date in dates {
                drafts.append(MedicationOCRDraft(name: name, kind: kind, date: date, sideEffects: sideEffects, notes: notes))
            }
        }

        if drafts.isEmpty {
            let notes = lines.joined(separator: " ")
            return [MedicationOCRDraft(name: fallbackName, kind: kind, date: firstDate(in: lines), sideEffects: fallbackSideEffects, notes: notes)]
        }

        return drafts
    }

    static func parseDiagnostic(text: String) -> DiagnosticOCRDraft {
        let lines = normalize(text)
        let date = firstDate(in: lines)
        let testName = extractTestName(from: lines.joined(separator: " "), matches: dateMatches(in: lines.joined(separator: " "))) ?? firstNonDateLine(in: lines) ?? "Unknown test"
        let result = extractResult(from: lines.joined(separator: " ")) ?? firstResult(in: lines) ?? "Result not specified"
        let notes = lines.joined(separator: " ")
        return DiagnosticOCRDraft(testName: testName, resultSummary: result, date: date, notes: notes)
    }

    static func parseMedication(text: String) -> MedicationOCRDraft {
        let lines = normalize(text)
        let date = firstDate(in: lines)
        let name = extractMedicationName(from: lines.joined(separator: " "), matches: dateMatches(in: lines.joined(separator: " "))) ?? firstNonDateLine(in: lines) ?? "Unknown medication"
        let kind = detectMedicationKind(in: lines)
        let sideEffects = extractSideEffects(from: lines.joined(separator: " ")) ?? detectSideEffects(in: lines) ?? "None"
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

        let spacedPattern = #"\b(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: spacedPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mRange = Range(match.range(at: 1), in: normalized),
                      let dRange = Range(match.range(at: 2), in: normalized),
                      let yRange = Range(match.range(at: 3), in: normalized) else { continue }
                let month = String(normalized[mRange])
                let day = String(normalized[dRange])
                let year = String(normalized[yRange])
                if let date = parseDateString("\(month)/\(day)/\(year)") {
                    results.append(date)
                }
            }
        }

        let compactPattern = #"\b(\d{3,4})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: compactPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mdRange = Range(match.range(at: 1), in: normalized),
                      let yRange = Range(match.range(at: 2), in: normalized) else { continue }
                let mdToken = String(normalized[mdRange])
                let year = String(normalized[yRange])
                if let date = parseCompactNumericDate(mdToken: mdToken, year: year) {
                    results.append(date)
                }
            }
        }

        let compactNoSpacePattern = #"\b(\d{3,4})(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: compactNoSpacePattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mdRange = Range(match.range(at: 1), in: normalized),
                      let yRange = Range(match.range(at: 2), in: normalized) else { continue }
                let mdToken = String(normalized[mdRange])
                let year = String(normalized[yRange])
                if let date = parseCompactNumericDate(mdToken: mdToken, year: year) {
                    results.append(date)
                }
            }
        }

        let monthPattern = #"\b([A-Za-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{2,4})\b"#
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

    private static func dateMatches(in text: String) -> [(range: Range<String.Index>, date: Date)] {
        let normalized = text
            .replacingOccurrences(of: "-", with: "/")
            .replacingOccurrences(of: ".", with: "/")
        var matches: [(Range<String.Index>, Date)] = []

        let numericPattern = #"\b(\d{1,2}/\d{1,2}/\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let r = Range(match.range(at: 1), in: normalized) else { continue }
                let token = String(normalized[r])
                if let date = parseDateString(token) {
                    matches.append((r, date))
                }
            }
        }

        let spacedPattern = #"\b(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: spacedPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mRange = Range(match.range(at: 1), in: normalized),
                      let dRange = Range(match.range(at: 2), in: normalized),
                      let yRange = Range(match.range(at: 3), in: normalized) else { continue }
                let month = String(normalized[mRange])
                let day = String(normalized[dRange])
                let year = String(normalized[yRange])
                if let date = parseDateString("\(month)/\(day)/\(year)") {
                    matches.append((mRange.lowerBound..<yRange.upperBound, date))
                }
            }
        }

        let compactPattern = #"\b(\d{3,4})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: compactPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mdRange = Range(match.range(at: 1), in: normalized),
                      let yRange = Range(match.range(at: 2), in: normalized) else { continue }
                let mdToken = String(normalized[mdRange])
                let year = String(normalized[yRange])
                if let date = parseCompactNumericDate(mdToken: mdToken, year: year) {
                    matches.append((mdRange.lowerBound..<yRange.upperBound, date))
                }
            }
        }

        let compactNoSpacePattern = #"\b(\d{3,4})(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: compactNoSpacePattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let mdRange = Range(match.range(at: 1), in: normalized),
                      let yRange = Range(match.range(at: 2), in: normalized) else { continue }
                let mdToken = String(normalized[mdRange])
                let year = String(normalized[yRange])
                if let date = parseCompactNumericDate(mdToken: mdToken, year: year) {
                    matches.append((mdRange.lowerBound..<yRange.upperBound, date))
                }
            }
        }

        let monthPattern = #"\b([A-Za-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: monthPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            for match in regex.matches(in: normalized, options: [], range: range) {
                guard let fullRange = Range(match.range(at: 0), in: normalized),
                      let mRange = Range(match.range(at: 1), in: normalized),
                      let dRange = Range(match.range(at: 2), in: normalized),
                      let yRange = Range(match.range(at: 3), in: normalized) else { continue }
                let month = String(normalized[mRange])
                let day = String(normalized[dRange])
                let year = String(normalized[yRange])
                if let date = parseMonthDate(month: month, day: day, year: year) {
                    matches.append((fullRange, date))
                }
            }
        }

        return matches.sorted(by: { lhs, rhs in
            lhs.0.lowerBound < rhs.0.lowerBound
        })
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
        if let monthDate = parseMonthDateFromText(cleaned) {
            return monthDate
        }
        if let compactDate = parseCompactDateFromText(cleaned) {
            return compactDate
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

    private static func parseCompactNumericDate(mdToken: String, year: String) -> Date? {
        let cleaned = mdToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 3, cleaned.count <= 4 else { return nil }
        let digits = cleaned.filter { $0.isNumber }
        guard digits.count == cleaned.count else { return nil }

        let month: Int
        let day: Int
        if digits.count == 3 {
            month = Int(String(digits.prefix(1))) ?? 0
            day = Int(String(digits.suffix(2))) ?? 0
        } else {
            month = Int(String(digits.prefix(2))) ?? 0
            day = Int(String(digits.suffix(2))) ?? 0
        }

        let yearDigits = year.filter { $0.isNumber }
        guard let y = Int(yearDigits), month >= 1, month <= 12, day >= 1, day <= 31 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "M/d/yyyy"
        return formatter.date(from: "\(month)/\(day)/\(y)")
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

    private static func parseMonthDateFromText(_ text: String) -> Date? {
        let pattern = #"\b([A-Za-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{2,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let mRange = Range(match.range(at: 1), in: text),
              let dRange = Range(match.range(at: 2), in: text),
              let yRange = Range(match.range(at: 3), in: text) else { return nil }
        let month = String(text[mRange]).replacingOccurrences(of: ".", with: "")
        let day = String(text[dRange])
        let year = String(text[yRange])
        return parseMonthDate(month: month, day: day, year: year)
    }

    private static func parseCompactDateFromText(_ text: String) -> Date? {
        let normalized = text.replacingOccurrences(of: "/", with: " ")
        let spacedPattern = #"\b(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: spacedPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            if let match = regex.firstMatch(in: normalized, options: [], range: range),
               let mRange = Range(match.range(at: 1), in: normalized),
               let dRange = Range(match.range(at: 2), in: normalized),
               let yRange = Range(match.range(at: 3), in: normalized) {
                let month = String(normalized[mRange])
                let day = String(normalized[dRange])
                let year = String(normalized[yRange])
                if let date = parseDateString("\(month)/\(day)/\(year)") {
                    return date
                }
            }
        }

        let compactPattern = #"\b(\d{3,4})\s+(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: compactPattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            if let match = regex.firstMatch(in: normalized, options: [], range: range),
               let mdRange = Range(match.range(at: 1), in: normalized),
               let yRange = Range(match.range(at: 2), in: normalized) {
                let mdToken = String(normalized[mdRange])
                let year = String(normalized[yRange])
                return parseCompactNumericDate(mdToken: mdToken, year: year)
            }
        }

        let compactNoSpacePattern = #"\b(\d{3,4})(\d{2,4})\b"#
        if let regex = try? NSRegularExpression(pattern: compactNoSpacePattern, options: []) {
            let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
            if let match = regex.firstMatch(in: normalized, options: [], range: range),
               let mdRange = Range(match.range(at: 1), in: normalized),
               let yRange = Range(match.range(at: 2), in: normalized) {
                let mdToken = String(normalized[mdRange])
                let year = String(normalized[yRange])
                return parseCompactNumericDate(mdToken: mdToken, year: year)
            }
        }

        return nil
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
        if lowered.contains("hepatitis a") {
            return "Hepatitis A"
        }
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

    private static func extractVaccineName(from line: String, matches: [(range: Range<String.Index>, date: Date)]) -> String? {
        guard let first = matches.first else { return nil }
        let prefix = line[..<first.range.lowerBound]
        let cleaned = prefix
            .replacingOccurrences(of: "on ", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "dated ", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func extractProvider(from line: String, matches: [(range: Range<String.Index>, date: Date)]) -> String? {
        let lowered = line.lowercased()
        if let range = lowered.range(of: #"(at|from|by|in)\s+.+$"#, options: .regularExpression) {
            let provider = line[range]
                .replacingOccurrences(of: "at ", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "from ", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "by ", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "in ", with: "", options: [.caseInsensitive])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return provider.isEmpty ? nil : provider
        }

        guard let last = matches.last else { return nil }
        let suffix = line[last.range.upperBound...]
        let cleaned = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return nil }
        let keywords = ["clinic", "hospital", "center", "centre", "health", "medical", "family", "care"]
        if keywords.contains(where: { cleaned.lowercased().contains($0) }) || cleaned.count > 3 {
            return cleaned
        }
        return nil
    }

    private static func removeProvider(from line: String, provider: String) -> String {
        guard provider.isEmpty == false else { return line }
        if let range = line.range(of: provider) {
            var trimmed = line
            trimmed.removeSubrange(range)
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return line
    }

    private static func removeRedundantVaccineInfo(from line: String, vaccineName: String) -> String {
        var working = line
        if vaccineName.isEmpty == false {
            if let range = working.range(of: vaccineName, options: [.caseInsensitive]) {
                working.removeSubrange(range)
            }
        }

        let freshMatches = dateMatches(in: working)
        for match in freshMatches.sorted(by: { $0.0.lowerBound > $1.0.lowerBound }) {
            let r = match.0
            if r.lowerBound >= working.startIndex && r.upperBound <= working.endIndex {
                working.removeSubrange(r)
            }
        }

        working = working
            .replacingOccurrences(of: "on", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "dated", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return working
    }

    private static func appendProviderNote(base: String, provider: String) -> String {
        guard provider.isEmpty == false else { return base }
        if base.isEmpty { return "Provider: \(provider)" }
        if base.lowercased().contains(provider.lowercased()) { return base }
        return "\(base) • Provider: \(provider)"
    }

    private static func extractTestName(from line: String, matches: [(range: Range<String.Index>, date: Date)]) -> String? {
        guard let first = matches.first else { return nil }
        let prefix = line[..<first.range.lowerBound]
        let cleaned = prefix
            .replacingOccurrences(of: "on ", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "dated ", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func extractMedicationName(from line: String, matches: [(range: Range<String.Index>, date: Date)]) -> String? {
        guard let first = matches.first else { return nil }
        let prefix = line[..<first.range.lowerBound]
        let cleaned = prefix
            .replacingOccurrences(of: "on ", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "started ", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func extractResult(from line: String) -> String? {
        let lowered = line.lowercased()
        let keywords = ["negative", "positive", "reactive", "non-reactive", "non reactive", "normal", "abnormal", "indeterminate", "inconclusive"]
        if let keyword = keywords.first(where: { lowered.contains($0) }) {
            return keyword.replacingOccurrences(of: "non reactive", with: "non-reactive").capitalized
        }
        if let range = lowered.range(of: #"result\s*(is|:)?\s*([a-zA-Z\- ]+)"#, options: .regularExpression) {
            let captured = String(line[range])
                .replacingOccurrences(of: "result", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "is", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if captured.isEmpty == false {
                let stopWords = [" at ", " from ", " by ", " in "]
                let trimmed = stopWords.reduce(captured) { current, word in
                    current.components(separatedBy: word).first ?? current
                }
                return trimmed.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
            }
        }
        return nil
    }

    private static func extractSideEffects(from line: String) -> String? {
        let lowered = line.lowercased()
        if let range = lowered.range(of: #"side effects?\s*(are|were|:)?\s*([a-zA-Z0-9 ,\-]+)"#, options: .regularExpression) {
            let captured = String(line[range])
                .replacingOccurrences(of: "side effects", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "side effect", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "are", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: "were", with: "", options: [.caseInsensitive])
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return captured.isEmpty ? nil : captured
        }
        if lowered.contains("made me") || lowered.contains("caused") {
            return line
        }
        return nil
    }

    private static func removeSideEffects(from line: String, sideEffects: String) -> String {
        guard sideEffects.isEmpty == false else { return line }
        if let range = line.range(of: sideEffects) {
            var trimmed = line
            trimmed.removeSubrange(range)
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return line
    }
}
