import Foundation
import Combine

final class VaccinesViewModel: ObservableObject {
    @Published var records: [VaccineRecord] = []
    @Published var selectedRegion: BodyRegion = .fullBody
    private var cancellables = Set<AnyCancellable>()

    var visibleRecords: [VaccineRecord] {
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
        if let stored: [VaccineRecord] = LocalStore.load("vaccines.json", as: [VaccineRecord].self) {
            records = stored
        } else {
            records = []
        }
        sortRecords()
        save()
    }

    func save() {
        LocalStore.save(records, filename: "vaccines.json")
    }

    func addRecord(_ record: VaccineRecord) {
        records.append(record)
        sortRecords()
        save()
    }

    func updateRecord(_ record: VaccineRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        sortRecords()
        save()
    }

    func deleteRecord(_ record: VaccineRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    private func sortRecords() {
        records.sort { $0.date > $1.date }
    }
}
