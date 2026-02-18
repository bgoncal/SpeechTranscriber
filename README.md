# SpeechTranscriber

A lightweight Swift package for real-time speech-to-text transcription using Apple's Speech framework.

## Features

- 🎤 Real-time speech transcription with partial results
- 🌍 Multi-locale support
- 📱 iOS 17+ and macOS 14+ support
- 🔄 Callback-based and Observable patterns
- 🎨 Ready-to-use SwiftUI components

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
