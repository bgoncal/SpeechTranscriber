import SwiftUI

/// A ready-to-use microphone button for speech transcription
public struct SpeechButton: View {
    @Bindable private var transcriber: SpeechTranscriber
    private let onTranscript: (String) -> Void
    
    @State private var showError = false
    @State private var errorText = ""
    
    /// Create a speech button
    /// - Parameters:
    ///   - transcriber: The SpeechTranscriber instance to use
    ///   - onTranscript: Called with the final transcript when done
    public init(
        transcriber: SpeechTranscriber,
        onTranscript: @escaping (String) -> Void
    ) {
        self.transcriber = transcriber
        self.onTranscript = onTranscript
    }
    
    public var body: some View {
        Button {
            Task {
                await toggleListening()
            }
        } label: {
            Image(systemName: transcriber.isListening ? "mic.fill" : "mic")
                .font(.title2)
                .foregroundStyle(transcriber.isListening ? .red : .primary)
                .symbolEffect(.pulse, isActive: transcriber.isListening)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorText)
        }
    }
    
    private func toggleListening() async {
        if transcriber.isListening {
            let finalTranscript = transcriber.transcript
            transcriber.stopListening()
            if !finalTranscript.isEmpty {
                onTranscript(finalTranscript)
            }
        } else {
            do {
                try await transcriber.startListening()
            } catch {
                errorText = error.localizedDescription
                showError = true
            }
        }
    }
}

/// A view that shows the live transcription preview
public struct TranscriptionPreview: View {
    @Bindable private var transcriber: SpeechTranscriber
    private let placeholder: String
    
    /// Create a transcription preview
    /// - Parameters:
    ///   - transcriber: The SpeechTranscriber instance
    ///   - placeholder: Text to show when no transcription yet
    public init(
        transcriber: SpeechTranscriber,
        placeholder: String = "Listening..."
    ) {
        self.transcriber = transcriber
        self.placeholder = placeholder
    }
    
    public var body: some View {
        if transcriber.isListening {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .opacity(transcriber.isListening ? 1 : 0)
                
                Text(transcriber.transcript.isEmpty ? placeholder : transcriber.transcript)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    @Previewable @State var transcriber = SpeechTranscriber()
    @Previewable @State var result = ""
    
    VStack(spacing: 20) {
        Text("Result: \(result)")
            .padding()
        
        TranscriptionPreview(transcriber: transcriber)
        
        SpeechButton(transcriber: transcriber) { transcript in
            result = transcript
        }
    }
    .padding()
}
