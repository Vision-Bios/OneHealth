import Foundation
import Combine

final class ExportViewModel: ObservableObject {
    @Published var exportURL: URL?
    @Published var isPresentingShare = false

    func export() {
        exportURL = ExportService.exportCSV()
        isPresentingShare = exportURL != nil
    }
}
