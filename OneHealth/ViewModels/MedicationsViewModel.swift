import Foundation
import Combine

final class MedicationsViewModel: ObservableObject {
    @Published var records: [MedicationRecord] = []
    @Published var selectedRegion: BodyRegion = .fullBody
    private var cancellables = Set<AnyCancellable>()

    var visibleRecords: [MedicationRecord] {
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
        if let stored: [MedicationRecord] = LocalStore.load("medications.json", as: [MedicationRecord].self) {
            records = stored
        } else {
            records = []
        }
        sortRecords()
        save()
    }

    func save() {
        LocalStore.save(records, filename: "medications.json")
    }

    func addRecord(_ record: MedicationRecord) {
        records.append(record)
        sortRecords()
        save()
    }

    func updateRecord(_ record: MedicationRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        sortRecords()
        save()
    }

    func deleteRecord(_ record: MedicationRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    private func sortRecords() {
        records.sort { $0.date > $1.date }
    }
}
