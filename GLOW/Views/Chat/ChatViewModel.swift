import SwiftUI
import Combine

/// The brain of the Glow chat screen.
/// Wires ClaudeService + SAMHSAService + LocationService + SystemPromptBuilder.

@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: — Published state

    @Published var messages:    [Message] = []
    @Published var inputText:   String    = ""
    @Published var isThinking:  Bool      = false
    @Published var errorBanner: String?   = nil
    @Published var resources:   [LocalResource] = []

    // MARK: — Dependencies

    private let claude   = ClaudeService()
    private let samhsa   = SAMHSAService()

    // MARK: — Session state

    private var systemPrompt: String = ""
    private var sessionReady: Bool   = false

    // MARK: — Init

    /// Call once when the chat screen appears.
    func startSession(appState: AppState, location: LocationService) async {
        guard !sessionReady else { return }
        sessionReady = true
        isThinking = true
        defer { isThinking = false }

        // 1. Fetch SAMHSA resources (uses coordinate if available, else falls back)
        if let coord = location.coordinate {
            resources = await samhsa.fetchResources(near: coord)
        } else {
            resources = []
        }

        // 2. Build the system prompt
        systemPrompt = SystemPromptBuilder.main(
            userName:    appState.userName,
            userAge:     appState.userAge,
            cityName:    location.cityName,
            streakDays:  appState.streakDays,
            moodHistory: appState.moodHistory,
            resources:   resources
        )

        // 3. Send the opening welcome
        await sendOpener(appState: appState)
    }

    // MARK: — Send message

    func send(appState: AppState) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }

        inputText   = ""
        isThinking  = true
        errorBanner = nil
        defer { isThinking = false }

        // Add user message immediately so UI updates
        let userMsg = Message(role: .user, content: text)
        messages.append(userMsg)

        do {
            let history = messages.dropLast().filter { !$0.content.hasPrefix("[opener]") }
            let reply   = try await claude.send(
                userMessage:  text,
                history:      Array(history),
                systemPrompt: systemPrompt
            )
            messages.append(Message(role: .assistant, content: reply))
        } catch {
            errorBanner = error.localizedDescription
        }
    }

    // MARK: — Private

    private func sendOpener(appState: AppState) async {
        let moodSummary = appState.moodHistory.suffix(5)
            .map { $0.mood.rawValue }
            .joined(separator: ", ")

        let openerPrompt = """
        [opener] Give \(appState.userName) a warm 2-sentence welcome. \
        Their mood this week: \(moodSummary.isEmpty ? "not logged yet" : moodSummary). \
        Streak: \(appState.streakDays) days. Be brief and natural.
        """

        do {
            let reply = try await claude.send(
                userMessage:  openerPrompt,
                history:      [],
                systemPrompt: systemPrompt
            )
            messages.append(Message(role: .assistant, content: reply))
        } catch {
            messages.append(Message(
                role: .assistant,
                content: "Hey \(appState.userName), I'm here. How are you feeling today?"
            ))
        }
    }
}
