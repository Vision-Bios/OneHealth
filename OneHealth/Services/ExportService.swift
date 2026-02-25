import Foundation

@MainActor
enum ExportService {
    static func exportCSV() -> URL? {
        let vaccines: [VaccineRecord] = LocalStore.load("vaccines.json", as: [VaccineRecord].self) ?? []
        let diagnostics: [DiagnosticResult] = LocalStore.load("diagnostics.json", as: [DiagnosticResult].self) ?? []
        let medications: [MedicationRecord] = LocalStore.load("medications.json", as: [MedicationRecord].self) ?? []

        let header = [
            "Type",
            "Record Name",
            "Provider",
            "Result",
            "Date (YYYY-MM-DD)",
            "Region",
            "Side Effects",
            "Notes",
            "Kind"
        ]

        var rows: [[String]] = [header]

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for record in vaccines {
            rows.append([
                "Vaccine",
                record.name,
                record.provider,
                "",
                dateFormatter.string(from: record.date),
                "",
                "",
                record.notes,
                ""
            ])
        }

        for record in diagnostics {
            rows.append([
                "Diagnostic",
                record.testName,
                "",
                record.resultSummary,
                dateFormatter.string(from: record.date),
                record.region.displayName,
                "",
                record.notes,
                ""
            ])
        }

        for record in medications {
            rows.append([
                "Medication",
                record.name,
                "",
                "",
                dateFormatter.string(from: record.date),
                record.region.displayName,
                record.sideEffects,
                record.notes,
                record.kind.displayName
            ])
        }

        let csv = rows.map { $0.map(csvEscape).joined(separator: ",") }.joined(separator: "\n")
        return writeFile(contents: csv)
    }

    static func importCSV(from url: URL) -> ImportOutcome {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return .failure("Unable to read the file.")
        }
        return importCSV(contents: contents)
    }

    static func importCSV(contents: String) -> ImportOutcome {
        let rows = parseCSV(contents)
        guard let header = rows.first, rows.count > 1 else {
            return .failure("The file is empty or missing headers.")
        }

        let normalizedHeader = header.map { $0.components(separatedBy: " ").first?.lowercased() ?? $0.lowercased() }
        let headerIndex = Dictionary(uniqueKeysWithValues: normalizedHeader.enumerated().map { ($0.element, $0.offset) })
        let records = rows.dropFirst()

        var vaccines: [VaccineRecord] = []
        var diagnostics: [DiagnosticResult] = []
        var medications: [MedicationRecord] = []

        let isoFormatter = ISO8601DateFormatter()
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        for row in records {
            let type = value("type", row, headerIndex).lowercased()
            let name = value("record", row, headerIndex)
            let provider = value("provider", row, headerIndex)
            let result = value("result", row, headerIndex)
            let dateString = value("date", row, headerIndex)
            let regionName = value("region", row, headerIndex)
            let sideEffects = value("side", row, headerIndex)
            let notes = value("notes", row, headerIndex)
            let kindValue = value("kind", row, headerIndex)

            if type.isEmpty && name.isEmpty && provider.isEmpty && result.isEmpty && notes.isEmpty {
                continue
            }

            let date = isoFormatter.date(from: dateString)
                ?? dateOnlyFormatter.date(from: dateString)
                ?? Date()
            let region = regionFromDisplayName(regionName) ?? .fullBody

            switch type {
            case "vaccine":
                let record = VaccineRecord(
                    id: UUID(),
                    name: name.isEmpty ? "Untitled Vaccine" : name,
                    date: date,
                    region: region,
                    provider: provider.isEmpty ? "Unknown provider" : provider,
                    notes: notes.isEmpty ? "No notes" : notes
                )
                vaccines.append(record)
            case "diagnostic":
                let record = DiagnosticResult(
                    id: UUID(),
                    testName: name.isEmpty ? "Untitled Test" : name,
                    resultSummary: result.isEmpty ? "No summary" : result,
                    date: date,
                    region: region,
                    notes: notes.isEmpty ? "No notes" : notes
                )
                diagnostics.append(record)
            case "medication":
                let kind = MedicationKind.allCases.first { $0.displayName.lowercased() == kindValue.lowercased() } ?? .medication
                let record = MedicationRecord(
                    id: UUID(),
                    name: name.isEmpty ? "Untitled" : name,
                    kind: kind,
                    date: date,
                    region: region,
                    sideEffects: sideEffects.isEmpty ? "None" : sideEffects,
                    notes: notes.isEmpty ? "No notes" : notes
                )
                medications.append(record)
            default:
                continue
            }
        }

        LocalStore.save(vaccines, filename: "vaccines.json")
        LocalStore.save(diagnostics, filename: "diagnostics.json")
        LocalStore.save(medications, filename: "medications.json")

        let total = vaccines.count + diagnostics.count + medications.count
        if total == 0 {
            return .failure("No records found. Check the spreadsheet format.")
        }
        NotificationCenter.default.post(name: .healthDataDidImport, object: nil)
        return .success(total)
    }

    private static func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private static func writeFile(contents: String) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let name = "OneHealth-Export-\(formatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func parseCSV(_ contents: String) -> [[String]] {
        let normalized = contents
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        let delimiter = detectDelimiter(from: lines.first.map(String.init) ?? "")
        return lines.map { parseCSVLine(String($0), delimiter: delimiter) }
    }

    private static func parseCSVLine(_ line: String, delimiter: Character) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let char = characters[index]
            if char == "\"" {
                if inQuotes && index + 1 < characters.count && characters[index + 1] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == delimiter && !inQuotes {
                values.append(current)
                current = ""
            } else {
                current.append(char)
            }
            index += 1
        }

        values.append(current)
        return values
    }

    private static func value(_ key: String, _ row: [String], _ headerIndex: [String: Int]) -> String {
        guard let index = headerIndex[key], index < row.count else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func regionFromDisplayName(_ name: String) -> BodyRegion? {
        BodyRegion.allCases.first { $0.displayName.lowercased() == name.lowercased() }
    }

    private static func detectDelimiter(from headerLine: String) -> Character {
        let candidates: [Character] = [",", "\t", ";"]
        let counts = candidates.map { delimiter in
            (delimiter, headerLine.filter { $0 == delimiter }.count)
        }
        return counts.max(by: { $0.1 < $1.1 })?.0 ?? ","
    }
}

enum ImportOutcome {
    case success(Int)
    case failure(String)
}
