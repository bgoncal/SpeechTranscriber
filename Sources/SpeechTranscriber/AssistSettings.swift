import Foundation
import SwiftUI

/// Settings model for configuring local audio transcription as an alternative to the assist websocket API.
///
/// Create an instance and pass it to ``AssistView`` and ``AssistSettingsView``.
/// Local transcription is disabled by default; users must explicitly opt in.
@MainActor
@Observable
public final class AssistSettings {

    // MARK: - Properties

    /// Whether local on-device audio transcription is enabled. Disabled by default (opt-in).
    public var isLocalTranscriptionEnabled: Bool = false

    /// The locale identifier for local transcription (e.g. `"en-US"`, `"pt-BR"`).
    /// When `nil`, the device's current locale is used.
    public var selectedLocaleIdentifier: String? = nil

    // MARK: - Computed Properties

    /// The ``Locale`` derived from ``selectedLocaleIdentifier``, or `nil` when none is selected.
    public var selectedLocale: Locale? {
        guard let id = selectedLocaleIdentifier else { return nil }
        return Locale(identifier: id)
    }

    /// Whether the selected locale is supported for on-device speech recognition.
    ///
    /// Returns `true` when no locale is explicitly selected (the device default will be used).
    /// Returns `false` when the chosen locale is not in `SpeechTranscriber.supportedLocales`,
    /// which typically means the language pack has not been downloaded on this device.
    public var isSelectedLocaleAvailable: Bool {
        guard let id = selectedLocaleIdentifier else { return true }
        return SpeechTranscriber.supportedLocales.contains(Locale(identifier: id))
    }

    // MARK: - Initialization

    public init() {}
}

// MARK: - AssistSettingsView

/// A SwiftUI form for configuring ``AssistSettings``.
///
/// Embed this inside a `NavigationStack` or `NavigationView` so the navigation title is visible.
///
/// ```swift
/// NavigationStack {
///     AssistSettingsView(settings: assistSettings)
/// }
/// ```
public struct AssistSettingsView: View {
    @Bindable private var settings: AssistSettings

    public init(settings: AssistSettings) {
        self.settings = settings
    }

    public var body: some View {
        Form {
            Section {
                Toggle("Use Local Transcription", isOn: $settings.isLocalTranscriptionEnabled)
            } header: {
                Text("Local Transcription")
            } footer: {
                Text(
                    "When enabled, speech is transcribed on-device instead of streaming audio to the cloud service. " +
                    "You must opt in to activate this feature."
                )
            }

            if settings.isLocalTranscriptionEnabled {
                Section {
                    Picker("Language", selection: $settings.selectedLocaleIdentifier) {
                        Text("Device Default").tag(nil as String?)
                        ForEach(SpeechTranscriber.supportedLocales, id: \.identifier) { locale in
                            Text(localeName(for: locale))
                                .tag(Optional(locale.identifier))
                        }
                    }

                    if !settings.isSelectedLocaleAvailable {
                        Label(
                            "The selected language is not available for local transcription. " +
                            "Download it in Settings → General → Language & Region.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text(
                        "Select the language for on-device recognition. " +
                        "Ensure the language pack is downloaded on your device."
                    )
                }
            }
        }
        .navigationTitle("Transcription Settings")
    }

    private func localeName(for locale: Locale) -> String {
        locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
    }
}
