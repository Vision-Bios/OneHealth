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
                VStack(spacing: 16) {
                    HeaderView(title: "Voice Entry", subtitle: kind.title)

                    Text(kind.helper)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Transcribed text")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                        }

                        ZStack(alignment: .topLeading) {
                            if transcriber.transcript.isEmpty {
                                Text("Your voice entry will appear here...")
                                    .foregroundColor(.white.opacity(0.45))
                                    .padding(.top, 6)
                            }

                            TextEditor(text: $transcriber.transcript)
                                .foregroundColor(.white)
                                .tint(.white)
                                .scrollContentBackground(.hidden)
                                .frame(height: 120)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 320)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        )
                        .frame(maxWidth: .infinity, alignment: .center)

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
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(transcriber.isRecording ? Color(red: 0.98, green: 0.47, blue: 0.47, opacity: 0.35) : Color.white.opacity(0.16))
                                )
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
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.24))
                            )
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 24)
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
