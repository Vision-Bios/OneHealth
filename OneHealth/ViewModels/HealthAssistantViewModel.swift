import Foundation
import Speech
import AVFoundation
import Combine

struct AssistantMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

final class HealthAssistantViewModel: ObservableObject {
    @Published var messages: [AssistantMessage] = []
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer()

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { _ in }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func submitText() {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        appendUserMessage(trimmed)
        let response = HealthQueryService.answer(for: trimmed)
        appendAssistantMessage(response)
        transcript = ""
    }

    private func startRecording() {
        errorMessage = nil
        requestPermissions()

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Microphone setup failed."
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Recording failed to start."
            return
        }

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.transcript = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }

        isRecording = true
    }

    private func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        isRecording = false
    }

    private func appendUserMessage(_ text: String) {
        messages.append(AssistantMessage(text: text, isUser: true))
    }

    private func appendAssistantMessage(_ text: String) {
        messages.append(AssistantMessage(text: text, isUser: false))
    }
}
