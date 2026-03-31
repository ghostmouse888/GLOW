import SwiftUI

struct SocialCoachView: View {
    private let claude = ClaudeService()

    @State private var selected: Scenario? = nil
    @State private var messages: [Message] = []
    @State private var input     = ""
    @State private var isThinking = false
    @State private var exchangeCount = 0
    @State private var showingFeedback = false

    private let purple      = Color(hex: "#7F77DD")
    private let purpleLight = Color(hex: "#EEEDFE")

    struct Scenario: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let roleDescription: String
    }

    private let scenarios: [Scenario] = [
        Scenario(title: "Friend conflict",
                 subtitle: "Work through a falling out",
                 icon: "person.2.fill",
                 roleDescription: "a friend you had a falling out with"),
        Scenario(title: "Talking to a parent",
                 subtitle: "Bring up something important",
                 icon: "house.fill",
                 roleDescription: "a parent you need to talk to"),
        Scenario(title: "Saying no",
                 subtitle: "Set a boundary kindly",
                 icon: "hand.raised.fill",
                 roleDescription: "someone you need to say no to"),
        Scenario(title: "Asking for help",
                 subtitle: "Reach out to a teacher",
                 icon: "graduationcap.fill",
                 roleDescription: "a teacher you need help from"),
    ]

    var body: some View {
        Group {
            if let scenario = selected {
                chatView(scenario: scenario)
            } else {
                pickerView
            }
        }
        .navigationTitle("Social coach")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Scenario picker

    private var pickerView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#F5F4FF"), Color(hex: "#EEEDFE")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(purple).font(.title3)
                        Text("Social coach").font(.title2.weight(.medium))
                        Spacer()
                    }
                    Text("Pick a scenario to practise.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(scenarios) { scenario in
                            Button { startSession(scenario) } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(purpleLight)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: scenario.icon)
                                            .foregroundStyle(purple)
                                            .font(.system(size: 18))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(scenario.title)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(Color(.label))
                                        Text(scenario.subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                .padding(16)
                                .background(Color(.systemBackground).opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Claude will play the other person. After a few exchanges it'll step back and give you kind feedback.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: — Chat view

    private func chatView(scenario: Scenario) -> some View {
        VStack(spacing: 0) {
            // Context bar
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(purpleLight)
                        .frame(width: 32, height: 32)
                    Image(systemName: scenario.icon)
                        .foregroundStyle(purple)
                        .font(.system(size: 13))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Practising with")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(scenario.title)
                        .font(.caption.weight(.semibold))
                }
                Spacer()
                Button("End") {
                    selected = nil
                    messages = []
                    exchangeCount = 0
                    showingFeedback = false
                    input = ""
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .overlay(alignment: .bottom) { Divider() }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            CoachBubble(message: msg, accentColor: purple)
                                .id(msg.id)
                        }
                        if isThinking {
                            HStack {
                                CoachTypingIndicator(color: purple)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id.uuidString ?? "typing", anchor: .bottom)
                    }
                }
                .onChange(of: isThinking) { _, thinking in
                    if thinking {
                        withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                    }
                }
            }

            // Feedback banner (after 4 exchanges)
            if showingFeedback, let last = messages.last, last.role == .assistant {
                // already shown inline as a message
            }

            // Input bar
            if !showingFeedback || messages.last?.role == .assistant {
                inputBar(scenario: scenario)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func inputBar(scenario: Scenario) -> some View {
        HStack(spacing: 10) {
            TextField("What do you say?", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                Task { await sendMessage(scenario: scenario) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking
                                     ? Color(.systemGray4) : purple)
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: — Logic

    private func startSession(_ scenario: Scenario) {
        selected = scenario
        messages = []
        exchangeCount = 0
        showingFeedback = false
        Task { await openingMessage(scenario: scenario) }
    }

    private func openingMessage(scenario: Scenario) async {
        isThinking = true
        let opener = (try? await claude.quick(
            prompt: "Start the role-play. Open with one short, realistic sentence as \(scenario.roleDescription). Don't introduce yourself — just begin the conversation naturally.",
            system: SystemPromptBuilder.socialCoach(scenario: scenario.roleDescription)
        )) ?? "Hey… I've been meaning to talk to you."
        messages.append(Message(role: .assistant, content: opener))
        isThinking = false
    }

    private func sendMessage(scenario: Scenario) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        input = ""
        messages.append(Message(role: .user, content: trimmed))
        exchangeCount += 1
        isThinking = true

        if exchangeCount >= 4 {
            // Step out of role and give feedback
            showingFeedback = true
            let feedback = (try? await claude.send(
                userMessage: "[Step out of the role-play now. Give brief, kind feedback on what the user did well and one thing to try next time. Be warm and specific. Under 80 words.]",
                history: messages,
                systemPrompt: SystemPromptBuilder.socialCoach(scenario: scenario.roleDescription)
            )) ?? "You did really well keeping the conversation going. One tip: try starting with how you feel before saying what you need — it can make the other person more open to listening."
            messages.append(Message(role: .assistant, content: "💬 " + feedback))
        } else {
            let reply = (try? await claude.send(
                userMessage: trimmed,
                history: messages.dropLast(),
                systemPrompt: SystemPromptBuilder.socialCoach(scenario: scenario.roleDescription)
            )) ?? "I hear you… can you tell me more?"
            messages.append(Message(role: .assistant, content: reply))
        }
        isThinking = false
    }
}

// MARK: — Supporting views

struct CoachBubble: View {
    let message: Message
    let accentColor: Color

    private var isUser: Bool { message.role == .user }
    private var isFeedback: Bool { message.content.hasPrefix("💬") }

    var body: some View {
        if isFeedback {
            VStack(alignment: .leading, spacing: 6) {
                Text("Glow's feedback")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                Text(message.content.dropFirst(2).trimmingCharacters(in: .whitespaces))
                    .font(.subheadline).lineSpacing(4)
                    .foregroundStyle(Color(.label))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#EEEDFE"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 4)
        } else {
            HStack {
                if isUser { Spacer(minLength: 60) }
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? accentColor : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                if !isUser { Spacer(minLength: 60) }
            }
        }
    }
}

struct CoachTypingIndicator: View {
    let color: Color
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(0.6))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 0.8)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { phase = 1 }
    }
}
