# SpeechTranscriber

A lightweight Swift package for real-time speech-to-text transcription using Apple's Speech framework.

## Features

- 🎤 Real-time speech transcription with partial results
- 🌍 Multi-locale support
- 📱 iOS 17+ and macOS 14+ support
- 🔄 Callback-based and Observable patterns
- 🎨 Ready-to-use SwiftUI components
- 🏠 Local (on-device) transcription opt-in via `AssistView` and `AssistSettings`

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bgoncal/SpeechTranscriber.git", from: "1.0.0")
]
```

Or add it via Xcode: File → Add Package Dependencies → paste the URL.

## Usage

### Basic Usage

```swift
import SpeechTranscriber

@State private var transcriber = SpeechTranscriber()

// Start listening
try await transcriber.startListening()

// Access real-time transcript
Text(transcriber.transcript)

// Stop listening
transcriber.stopListening()
```

### With Specific Locale

```swift
// Portuguese (Brazil)
let transcriber = SpeechTranscriber(localeIdentifier: "pt-BR")

// Or with Locale object
let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"))
```

### Using Callbacks

```swift
let transcriber = SpeechTranscriber()

transcriber.onTranscriptUpdate = { text, isFinal in
    print("Transcript: \(text), Final: \(isFinal)")
}

transcriber.onError = { error in
    print("Error: \(error.localizedDescription)")
}

transcriber.onListeningStateChange = { isListening in
    print("Listening: \(isListening)")
}
```

### SwiftUI Components

```swift
import SpeechTranscriber

struct ContentView: View {
    @State private var transcriber = SpeechTranscriber()
    @State private var result = ""
    
    var body: some View {
        VStack {
            // Shows live transcription preview
            TranscriptionPreview(transcriber: transcriber)
            
            // Ready-to-use mic button
            SpeechButton(transcriber: transcriber) { transcript in
                result = transcript
            }
            
            Text("Result: \(result)")
        }
    }
}
```

### Check Permissions

```swift
// Check current status
let status = SpeechTranscriber.authorizationStatus

// Request permissions explicitly
let granted = await transcriber.requestPermission()
```

### Get Supported Locales

```swift
let locales = SpeechTranscriber.supportedLocales
// Returns array of Locale objects supported for speech recognition
```

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 5.9+

## Privacy

Add these keys to your app's `Info.plist`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is used for voice input.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice input.</string>
```

## License

MIT License

---

## Local Transcription (Assist Feature)

The library ships an opt-in local (on-device) transcription flow via `AssistSettings` and `AssistView`. By default transcription continues to use the assist websocket API; users must explicitly enable local transcription.

### How it works

| Setting | Behaviour |
|---------|-----------|
| `isLocalTranscriptionEnabled = false` (default) | `AssistView` delegates audio directly to the `AssistWebSocketService` in *audio mode* |
| `isLocalTranscriptionEnabled = true` | `AssistView` initialises the websocket in *text mode*, runs `SpeechTranscriber` on-device, then forwards the final transcript via `sendText(_:)` |

If local transcription fails to start or encounters an error mid-session, `AssistView` falls back gracefully to websocket audio mode.

### Enabling local transcription

```swift
import SpeechTranscriber

// 1. Create and configure settings
@State private var assistSettings = AssistSettings()

// 2. Show AssistView (optionally wired to your websocket service)
AssistView(settings: assistSettings, webSocketService: myService) { result in
    print("Transcription result:", result)
}
```

### Showing the settings UI

```swift
NavigationStack {
    AssistSettingsView(settings: assistSettings)
}
```

The settings form exposes:
- **Use Local Transcription** toggle (off by default).
- **Language** picker (visible only when local transcription is enabled). Selecting *Device Default* uses the current device locale.
- An inline warning when the selected language pack is not downloaded on the device.

### Selecting a language

```swift
// Programmatically pre-select a language
assistSettings.selectedLocaleIdentifier = "pt-BR"

// Check whether the chosen locale is available on this device
if !assistSettings.isSelectedLocaleAvailable {
    print("Language pack not available – download it in Settings")
}
```

### Implementing `AssistWebSocketService`

```swift
class MyWebSocketService: AssistWebSocketService {
    func startInAudioMode() async throws { /* stream mic audio to server */ }
    func startInTextMode() async throws  { /* prepare server to receive text */ }
    func sendText(_ text: String) async throws { /* forward transcript */ }
    func stop() { /* close connection */ }
}
```

Pass `nil` for `webSocketService` if you only need local transcription without a backend.

### Troubleshooting

| Problem | Solution |
|---------|---------|
| "Speech recognition not available" | Ensure `NSSpeechRecognitionUsageDescription` is in `Info.plist` and the user has granted permission. |
| Selected language shows warning | Open Settings → General → Language & Region and download the language pack. |
| Fallback to cloud unexpectedly | Local transcription fell back due to an error (e.g. microphone permission denied). Check the `onError` callback or device logs. |
