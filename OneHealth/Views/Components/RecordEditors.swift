import SwiftUI

struct VaccineEditorView: View {
    let record: VaccineRecord?
    let defaultRegion: BodyRegion
    let onSave: (VaccineRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var date: Date
    @State private var region: BodyRegion
    @State private var provider: String
    @State private var notes: String

    init(record: VaccineRecord?, defaultRegion: BodyRegion, onSave: @escaping (VaccineRecord) -> Void) {
        self.record = record
        self.defaultRegion = defaultRegion
        self.onSave = onSave
        _name = State(initialValue: record?.name ?? "")
        _date = State(initialValue: record?.date ?? Date())
        _region = State(initialValue: record?.region ?? defaultRegion)
        _provider = State(initialValue: record?.provider ?? "")
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vaccine") {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Details") {
                    TextField("Provider", text: $provider)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(record == nil ? "New Vaccine" : "Edit Vaccine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = VaccineRecord(
                            id: record?.id ?? UUID(),
                            name: name.isEmpty ? "Untitled Vaccine" : name,
                            date: date,
                            region: region,
                            provider: provider.isEmpty ? "Unknown provider" : provider,
                            notes: notes.isEmpty ? "No notes" : notes
                        )
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DiagnosticEditorView: View {
    let record: DiagnosticResult?
    let defaultRegion: BodyRegion
    let onSave: (DiagnosticResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var testName: String
    @State private var resultSummary: String
    @State private var date: Date
    @State private var region: BodyRegion
    @State private var notes: String

    init(record: DiagnosticResult?, defaultRegion: BodyRegion, onSave: @escaping (DiagnosticResult) -> Void) {
        self.record = record
        self.defaultRegion = defaultRegion
        self.onSave = onSave
        _testName = State(initialValue: record?.testName ?? "")
        _resultSummary = State(initialValue: record?.resultSummary ?? "")
        _date = State(initialValue: record?.date ?? Date())
        _region = State(initialValue: record?.region ?? defaultRegion)
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Diagnostic") {
                    TextField("Test name", text: $testName)
                    TextField("Result", text: $resultSummary)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Body region", selection: $region) {
                        ForEach(BodyRegion.allCases) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(record == nil ? "New Diagnostic" : "Edit Diagnostic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = DiagnosticResult(
                            id: record?.id ?? UUID(),
                            testName: testName.isEmpty ? "Untitled Test" : testName,
                            resultSummary: resultSummary.isEmpty ? "No summary" : resultSummary,
                            date: date,
                            region: region,
                            notes: notes.isEmpty ? "No notes" : notes
                        )
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MedicationEditorView: View {
    let record: MedicationRecord?
    let defaultRegion: BodyRegion
    let onSave: (MedicationRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var kind: MedicationKind
    @State private var date: Date
    @State private var region: BodyRegion
    @State private var sideEffects: String
    @State private var notes: String

    init(record: MedicationRecord?, defaultRegion: BodyRegion, onSave: @escaping (MedicationRecord) -> Void) {
        self.record = record
        self.defaultRegion = defaultRegion
        self.onSave = onSave
        _name = State(initialValue: record?.name ?? "")
        _kind = State(initialValue: record?.kind ?? .medication)
        _date = State(initialValue: record?.date ?? Date())
        _region = State(initialValue: record?.region ?? defaultRegion)
        _sideEffects = State(initialValue: record?.sideEffects ?? "")
        _notes = State(initialValue: record?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(MedicationKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Body region", selection: $region) {
                        ForEach(BodyRegion.allCases) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                }

                Section("Side effects") {
                    TextField("Describe any side effects", text: $sideEffects, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(record == nil ? "New Medication" : "Edit Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = MedicationRecord(
                            id: record?.id ?? UUID(),
                            name: name.isEmpty ? "Untitled" : name,
                            kind: kind,
                            date: date,
                            region: region,
                            sideEffects: sideEffects.isEmpty ? "None" : sideEffects,
                            notes: notes.isEmpty ? "No notes" : notes
                        )
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}
