import Testing
@testable import SpeechTranscriber

// MARK: - AssistSettings Tests

@Test func assistSettingsDefaultsToLocalTranscriptionDisabled() async throws {
    let settings = await AssistSettings()
    let isEnabled = await settings.isLocalTranscriptionEnabled
    #expect(!isEnabled, "Local transcription should be disabled by default")
}

@Test func assistSettingsDefaultLocaleIdentifierIsNil() async throws {
    let settings = await AssistSettings()
    let id = await settings.selectedLocaleIdentifier
    #expect(id == nil, "No locale identifier should be selected by default")
}

@Test func assistSettingsSelectedLocaleIsNilWhenNoIdentifier() async throws {
    let settings = await AssistSettings()
    let locale = await settings.selectedLocale
    #expect(locale == nil, "Selected locale should be nil when no identifier is set")
}

@Test func assistSettingsSelectedLocaleMatchesIdentifier() async throws {
    let settings = await AssistSettings()
    await MainActor.run { settings.selectedLocaleIdentifier = "en-US" }
    let locale = await settings.selectedLocale
    #expect(locale?.identifier == "en-US", "Selected locale should match the set identifier")
}

@Test func assistSettingsLocaleAvailableWhenNoneSelected() async throws {
    let settings = await AssistSettings()
    let isAvailable = await settings.isSelectedLocaleAvailable
    #expect(isAvailable, "Locale should be considered available when no identifier is selected")
}

@Test func assistSettingsLocaleUnavailableForInvalidIdentifier() async throws {
    let settings = await AssistSettings()
    await MainActor.run { settings.selectedLocaleIdentifier = "xx-INVALID" }
    let isAvailable = await settings.isSelectedLocaleAvailable
    #expect(!isAvailable, "An invalid locale identifier should not be reported as available")
}

@Test func assistSettingsEnablingLocalTranscription() async throws {
    let settings = await AssistSettings()
    await MainActor.run { settings.isLocalTranscriptionEnabled = true }
    let isEnabled = await settings.isLocalTranscriptionEnabled
    #expect(isEnabled, "Local transcription should be enabled after setting the flag to true")
}

@Test func assistSettingsDisablingLocalTranscription() async throws {
    let settings = await AssistSettings()
    await MainActor.run {
        settings.isLocalTranscriptionEnabled = true
        settings.isLocalTranscriptionEnabled = false
    }
    let isEnabled = await settings.isLocalTranscriptionEnabled
    #expect(!isEnabled, "Local transcription should be disabled after toggling back to false")
}
