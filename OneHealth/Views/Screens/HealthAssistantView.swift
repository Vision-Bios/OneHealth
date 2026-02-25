import SwiftUI

struct HealthAssistantView: View {
    @StateObject private var viewModel = HealthAssistantViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                HealthArtBackground()

                VStack(spacing: 16) {
                    HeaderView(
                        title: "Health Assistant",
                        subtitle: "Ask about vaccines, diagnostics, or medications."
                    )

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white.opacity(0.7))

                            TextField("Ask a question or use the mic", text: $viewModel.transcript)
                                .foregroundColor(.white)
                                .tint(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        )

                        HStack(spacing: 12) {
                            Button(action: viewModel.toggleRecording) {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    Text(viewModel.isRecording ? "Stop" : "Speak")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(viewModel.isRecording ? Color(red: 0.98, green: 0.47, blue: 0.47, opacity: 0.35) : Color.white.opacity(0.16))
                                )
                            }
                            .buttonStyle(.plain)

                            Button("Send") {
                                viewModel.submitText()
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
                    .padding(.bottom, 12)
                }
                .padding(.top, 24)
            }
        }
        .onAppear {
            viewModel.requestPermissions()
        }
        .alert("Speech Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct MessageBubble: View {
    let message: AssistantMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.text)
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? Color.white.opacity(0.24) : Color.white.opacity(0.12))
                )
                .frame(maxWidth: 260, alignment: message.isUser ? .trailing : .leading)
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    HealthAssistantView()
}
