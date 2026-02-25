import SwiftUI

struct VaccinesView: View {
    @StateObject private var viewModel = VaccinesViewModel()
    @State private var isPresentingAdd = false
    @State private var editingRecord: VaccineRecord?
    @State private var isPresentingScanner = false
    @State private var isPresentingCamera = false
    @State private var scannedImage: UIImage?
    @State private var ocrDraft: VaccineOCRDraft?
    @State private var ocrDrafts: [VaccineOCRDraft] = []
    @State private var isPresentingVoice = false

    var body: some View {
        NavigationStack {
            ZStack {
                HealthArtBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(
                            title: "Vaccines",
                            subtitle: "Tap the plus button and add your vaccine record."
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)

                        VStack(spacing: 14) {
                            ForEach(viewModel.visibleRecords) { record in
                                VaccineCard(
                                    record: record,
                                    onEdit: { editingRecord = record },
                                    onDelete: { viewModel.deleteRecord(record) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Capture Photo") {
                            isPresentingCamera = true
                        }
                        Button("Upload Photo") {
                            isPresentingScanner = true
                        }
                        Button("Voice Entry") {
                            isPresentingVoice = true
                        }
                        Button("Add Manually") {
                            isPresentingAdd = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add vaccine")
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
        .sheet(isPresented: $isPresentingAdd) {
            VaccineEditorView(record: nil, defaultRegion: viewModel.selectedRegion) { record in
                viewModel.addRecord(record)
            }
        }
        .sheet(item: $editingRecord) { record in
            VaccineEditorView(record: record, defaultRegion: viewModel.selectedRegion) { updated in
                viewModel.updateRecord(updated)
            }
        }
        .sheet(isPresented: $isPresentingScanner) {
            PhotoPicker(selectedImage: $scannedImage)
        }
        .fullScreenCover(isPresented: $isPresentingCamera) {
            CameraCaptureView(selectedImage: $scannedImage)
        }
        .sheet(isPresented: $isPresentingVoice) {
            VoiceEntryView(kind: .vaccine) { text in
                let drafts = OCRParsers.parseVaccineEntries(text: text)
                if drafts.count <= 1 {
                    ocrDraft = drafts.first
                } else {
                    ocrDrafts = drafts
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { ocrDrafts.isEmpty == false },
            set: { if !$0 { ocrDrafts = [] } }
        )) {
            VaccineOCRReviewView(drafts: ocrDrafts) { drafts in
                for draft in drafts {
                    let record = VaccineRecord(
                        id: UUID(),
                        name: draft.name,
                        date: draft.date ?? Date(),
                        region: viewModel.selectedRegion,
                        provider: "",
                        notes: draft.notes
                    )
                    viewModel.addRecord(record)
                }
                ocrDrafts = []
            }
        }
        .sheet(item: $ocrDraft) { draft in
            VaccineEditorView(
                record: VaccineRecord(
                    id: UUID(),
                    name: draft.name,
                    date: draft.date ?? Date(),
                    region: viewModel.selectedRegion,
                    provider: "Unknown provider",
                    notes: draft.notes
                ),
                defaultRegion: viewModel.selectedRegion
            ) { record in
                viewModel.addRecord(record)
            }
        }
        .onChange(of: scannedImage) { _, newImage in
            guard let image = newImage else { return }
            OCRService.recognizeText(from: image) { text in
                let drafts = OCRParsers.parseVaccineEntries(text: text)
                DispatchQueue.main.async {
                    if drafts.count <= 1 {
                        ocrDraft = drafts.first
                    } else {
                        ocrDrafts = drafts
                    }
                }
            }
        }
    }
}

private struct VaccineOCRReviewView: View {
    let drafts: [VaccineOCRDraft]
    let onAdd: ([VaccineOCRDraft]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(drafts) { draft in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(draft.name)
                                .font(.headline)
                            if let date = draft.date {
                                Text(HealthDateFormatter.shortDate.string(from: date))
                                    .font(.subheadline)
                            }
                            Text(draft.notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: selectedIds.contains(draft.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.accentColor)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggle(draft.id)
                    }
                }
            }
            .navigationTitle("Add Vaccines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let selected = drafts.filter { selectedIds.contains($0.id) }
                        onAdd(selected)
                        dismiss()
                    }
                    .disabled(selectedIds.isEmpty)
                }
            }
        }
        .onAppear {
            selectedIds = Set(drafts.map(\.id))
        }
    }

    private func toggle(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

private struct VaccineCard: View {
    let record: VaccineRecord
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(record.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Text(record.notes)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 16) {
                Label(HealthDateFormatter.shortDate.string(from: record.date), systemImage: "calendar")
                Label(record.provider, systemImage: "cross.case")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.75))
        }
        .padding(16)
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
    VaccinesView()
}
