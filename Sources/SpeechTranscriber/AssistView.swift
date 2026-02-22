import SwiftUI

// MARK: - AssistWebSocketService

/// Defines the assist websocket API used for cloud-based audio transcription.
///
/// Implement this protocol in your app and pass the instance to ``AssistView``.
/// ``AssistView`` calls `startInAudioMode()` for remote transcription and
/// `startInTextMode()` + `sendText(_:)` when local transcription is active so
/// that the final transcript can still be forwarded through the assist pipeline.
public protocol AssistWebSocketService: AnyObject {
    /// Start the session in audio mode, streaming raw microphone audio to the server.
    func startInAudioMode() async throws
    /// Start the session in text mode so that on-device transcripts can be forwarded as text.
    func startInTextMode() async throws
    /// Send a completed transcript string to the server (used in text mode).
    func sendText(_ text: String) async throws
    /// Stop the websocket session and release any held resources.
    func stop()
}

// MARK: - AssistView

/// A SwiftUI view that manages audio transcription using either local (on-device) or
/// websocket-based (cloud) recognition, controlled by an ``AssistSettings`` instance.
///
/// **Behavior:**
/// - When ``AssistSettings/isLocalTranscriptionEnabled`` is `false` (default), tapping the
///   microphone button delegates directly to the ``AssistWebSocketService`` in audio mode.
/// - When local transcription is enabled, the view initialises the websocket in *text mode*,
///   runs `SpeechTranscriber` on-device, then forwards the final transcript via
///   `AssistWebSocketService/sendText(_:)`.
/// - If local transcription fails to start or encounters an error mid-session, the view
///   gracefully falls back to websocket audio mode.
///
/// ```swift
/// AssistView(settings: assistSettings, webSocketService: myService) { result in
///     print("Result:", result)
/// }
/// ```
public struct AssistView: View {
    @Bindable private var settings: AssistSettings
    private let webSocketService: (any AssistWebSocketService)?
    private let onResult: (String) -> Void

    @State private var transcriber: SpeechTranscriber?
    @State private var isListening = false
    @State private var isUsingLocalTranscription = false
    @State private var showError = false
    @State private var errorText = ""

    /// Create an ``AssistView``.
    /// - Parameters:
    ///   - settings: Settings that control whether local transcription is used.
    ///   - webSocketService: An optional websocket service for cloud-based transcription.
    ///     Pass `nil` when only local transcription is desired.
    ///   - onResult: Called on the main actor with the final transcription string.
    public init(
        settings: AssistSettings,
        webSocketService: (any AssistWebSocketService)? = nil,
        onResult: @escaping (String) -> Void
    ) {
        self.settings = settings
        self.webSocketService = webSocketService
        self.onResult = onResult
    }

    public var body: some View {
        VStack(spacing: 16) {
            if isListening {
                if let transcriber {
                    TranscriptionPreview(transcriber: transcriber)
                }

                Label(
                    isUsingLocalTranscription ? "Local transcription" : "Cloud transcription",
                    systemImage: isUsingLocalTranscription ? "iphone" : "cloud"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }

            Button {
                Task {
                    await toggleListening()
                }
            } label: {
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.title2)
                    .foregroundStyle(isListening ? .red : .primary)
                    .symbolEffect(.pulse, isActive: isListening)
            }
        }
        .animation(.default, value: isListening)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorText)
        }
    }

    // MARK: - Private

    private func toggleListening() async {
        if isListening {
            stopListening()
        } else {
            await startListening()
        }
    }

    private func startListening() async {
        if settings.isLocalTranscriptionEnabled {
            await startLocalTranscription()
        } else {
            await startWebSocketTranscription()
        }
    }

    private func startLocalTranscription() async {
        let locale = settings.selectedLocale
        let t: SpeechTranscriber = locale.map { SpeechTranscriber(locale: $0) } ?? SpeechTranscriber()

        t.onTranscriptUpdate = { text, isFinal in
            if isFinal && !text.isEmpty {
                Task { @MainActor in
                    try? await webSocketService?.sendText(text)
                    onResult(text)
                    stopListening()
                }
            }
        }

        t.onError = { _ in
            // Gracefully fall back to websocket audio transcription
            Task { @MainActor in
                isListening = false
                isUsingLocalTranscription = false
                transcriber = nil
                await startWebSocketTranscription()
            }
        }

        transcriber = t
        isUsingLocalTranscription = true
        isListening = true

        // Initialise websocket in text mode so the assist pipeline is ready to receive text
        try? await webSocketService?.startInTextMode()

        do {
            try await t.startListening()
        } catch {
            // Fall back to websocket audio mode on initialisation failure
            transcriber = nil
            isUsingLocalTranscription = false
            await startWebSocketTranscription()
        }
    }

    private func startWebSocketTranscription() async {
        isUsingLocalTranscription = false
        isListening = true
        do {
            try await webSocketService?.startInAudioMode()
        } catch {
            errorText = error.localizedDescription
            showError = true
            isListening = false
        }
    }

    private func stopListening() {
        transcriber?.stopListening()
        transcriber = nil
        isListening = false
        isUsingLocalTranscription = false
        webSocketService?.stop()
    }
}
