import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechManager: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var reply = ""
    @Published var isListening = false
    @Published var errorMessage = ""

    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var tapInstalled = false

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }

                guard status == .authorized else {
                    self.errorMessage = "Speech recognition permission was not granted."
                    return
                }

                self.startListening()
            }
        }
    }

    func startListening() {
        guard !isListening else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is currently unavailable."
            return
        }

        stopListening()
        transcript = ""
        errorMessage = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        tapInstalled = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true

            recognitionTask = speechRecognizer.recognitionTask(with: request) {
                [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString

                        if result.isFinal {
                            let message = self.transcript.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            self.stopListening()
                            if !message.isEmpty {
                                self.sendMessage(message)
                            }
                        }
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        self.stopListening()
                    }
                }
            }
        } catch {
            errorMessage = "Could not start the microphone: \(error.localizedDescription)"
            stopListening()
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    func sendMessage(_ message: String) {
        errorMessage = ""

        Task {
            do {
                let response = try await AIManager1.shared.sendMessage(message)
                reply = response

                let utterance = AVSpeechUtterance(string: response)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                synthesizer.speak(utterance)
            } catch {
                errorMessage = "JARVIS could not reply: \(error.localizedDescription)"
            }
        }
    }
}
