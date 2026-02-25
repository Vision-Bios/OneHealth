import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct DataHandlingView: View {
    @StateObject private var exportViewModel = ExportViewModel()
    @State private var isImporting = false
    @State private var importMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                HealthArtBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(
                            title: "Data Handling",
                            subtitle: "Backup, restore, and move your health records."
                        )

                        VStack(spacing: 12) {
                            ExportButton {
                                exportViewModel.export()
                            }

                            ImportButton {
                                isImporting = true
                            }

                            PasteButton {
                                handlePasteImport()
                            }
                        }

                        InfoCard(
                            title: "How it works",
                            message: "Export creates a CSV file that you can share via airdrop or other means. Import restores records into the app from the same CSV file (keeping the same format here is important). Paste CSV works without iCloud, and on your Mac you can highlight the data from the CSV file and then right click to copy to clipboard, in the app click on paste CSV and all that data will be imported into the app in the correct fromat."
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .sheet(isPresented: $exportViewModel.isPresentingShare) {
            if let url = exportViewModel.exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Status", isPresented: Binding(
            get: { importMessage != nil },
            set: { _ in importMessage = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(importMessage ?? "")
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let outcome = ExportService.importCSV(from: url)
            switch outcome {
            case .success(let count):
                importMessage = "Imported \(count) records."
            case .failure(let message):
                importMessage = message
            }
        } catch {
            importMessage = "Failed to import the file."
        }
    }

    private func handlePasteImport() {
        guard let text = UIPasteboard.general.string,
              text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            importMessage = "Clipboard is empty. Copy the CSV text first."
            return
        }

        let outcome = ExportService.importCSV(contents: text)
        switch outcome {
        case .success(let count):
            importMessage = "Imported \(count) records."
        case .failure(let message):
            importMessage = message
        }
    }
}

private struct ExportButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                Text("Export Data")
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ImportButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down")
                Text("Import Data")
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PasteButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "doc.on.clipboard")
                Text("Paste CSV")
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct InfoCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DataHandlingView()
}
