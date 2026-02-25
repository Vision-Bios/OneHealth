import Foundation
import Combine

final class DiagnosticsViewModel: ObservableObject {
    @Published var records: [DiagnosticResult] = []
    @Published var selectedRegion: BodyRegion = .fullBody
    private var cancellables = Set<AnyCancellable>()

    var visibleRecords: [DiagnosticResult] {
        if selectedRegion == .fullBody {
            return records
        }
        return records.filter { $0.region == selectedRegion }
    }

    init() {
        load()
        NotificationCenter.default.publisher(for: .healthDataDidImport)
            .sink { [weak self] _ in
                self?.load()
            }
            .store(in: &cancellables)
    }

    func load() {
        if let stored: [DiagnosticResult] = LocalStore.load("diagnostics.json", as: [DiagnosticResult].self) {
            records = stored
        } else {
            records = []
        }
        sortRecords()
        save()
    }

    func save() {
        LocalStore.save(records, filename: "diagnostics.json")
    }

    func addRecord(_ record: DiagnosticResult) {
        records.append(record)
        sortRecords()
        save()
    }

    func updateRecord(_ record: DiagnosticResult) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        sortRecords()
        save()
    }

    func deleteRecord(_ record: DiagnosticResult) {
        records.removeAll { $0.id == record.id }
        save()
    }

    private func sortRecords() {
        records.sort { $0.date > $1.date }
    }
}
