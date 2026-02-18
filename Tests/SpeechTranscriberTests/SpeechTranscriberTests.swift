import Testing
@testable import SpeechTranscriber

@Test func supportedLocalesNotEmpty() async throws {
    let locales = SpeechTranscriber.supportedLocales
    #expect(!locales.isEmpty, "Should have at least one supported locale")
}

@Test func initializationWithLocale() async throws {
    let transcriber = await SpeechTranscriber(localeIdentifier: "en-US")
    let locale = await transcriber.currentLocale
    #expect(locale.contains("en"), "Should use English locale")
}
