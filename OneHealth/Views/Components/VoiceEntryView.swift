import SwiftUI

enum VoiceEntryKind {
    case vaccine
    case diagnostic
    case medication

    var title: String {
        switch self {
        case .vaccine:
            return "Add Vaccines by Voice"
        case .diagnostic:
            return "Add Diagnostics by Voice"
        case .medication:
            return "Add Medications by Voice"
        }
    }

    var helper: String {
        switch self {
        case .vaccine:
            return "Say vaccine name, dates, and provider. Example: Varicella on 8/26/2013 and 11/26/2013 at San Diego clinic."
        case .diagnostic:
            return "Say test name, date, and result. Example: TB test on 6/29/2014, negative."
        case .medication:
            return "Say medication name, date, and side effects. Example: Vitamin D on 1/10/2020, no side effects."
        }
    }
}

struct VoiceEntryView: View {
    let kind: VoiceEntryKind
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var transcriber = SpeechTranscriber()

    var body: some View {
        NavigationStack {
            ZStack {
                HealthArtBackground()
                VStack(alignment: .leading, spacing: 16) {
                    HeaderView(title: "Voice Entry", subtitle: kind.title)

                    Text(kind.helper)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))

                    TextEditor(text: $transcriber.transcript)
                        .frame(minHeight: 160)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Button {
                            transcriber.toggleRecording()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: transcriber.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                Text(transcriber.isRecording ? "Stop" : "Record")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.18)))
                        }
                        .buttonStyle(.plain)

                        Button("Use Text") {
                            let text = transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard text.isEmpty == false else { return }
                            onComplete(text)
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.28)))
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(20)
            }
        }
        .onAppear {
            transcriber.requestPermissions()
        }
        .alert("Speech Error", isPresented: Binding(
            get: { transcriber.errorMessage != nil },
            set: { _ in transcriber.errorMessage = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(transcriber.errorMessage ?? "")
        }
    }
}
