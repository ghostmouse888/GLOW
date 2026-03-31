import SwiftUI
import Combine

// MARK: — Vent (combined Vent Mode + Clear Your Head)
// Phase 1: Vent freely — Claude only listens
// Phase 2: Optional thought reframe built into the same flow
// Nothing saved. Advice and reframe only if asked.

struct VentView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = VentViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "#0f0f18").ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                messageList
                if vm.showReframeOffer  { reframeOfferBar }
                if vm.showAdviceOffer   { adviceOfferBar }
                if vm.showReframePanel  { reframePanel }
                else                    { inputBar }
            }
        }
        .navigationBarHidden(true)
        .onAppear { vm.startSession() }
        .onDisappear { vm.clearSession() }
    }

    // MARK: — Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Vent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Nothing is saved")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            Button { vm.clearSession(); vm.startSession() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
        }
    }

    // MARK: — Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    privacyNotice
                    ForEach(vm.messages) { msg in
                        VentBubble(message: msg).id(msg.id)
                    }
                    if vm.isThinking { VentTypingIndicator().id("typing") }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation {
                    if let lastId = vm.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    } else {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var privacyNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.white.opacity(0.25))
            Text("This conversation isn't saved. Say whatever you need to.")
                .font(.caption2).foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    // MARK: — Offer bars

    private var reframeOfferBar: some View {
        HStack(spacing: 10) {
            Text("Want to flip that thought around?")
                .font(.caption).foregroundStyle(.white.opacity(0.55))
            Spacer()
            Button("Try it") {
                Task { await vm.startReframe() }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(hex: "#7F77DD"))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(hex: "#7F77DD").opacity(0.15))
            .clipShape(Capsule())

            Button("Not now") {
                withAnimation { vm.showReframeOffer = false }
            }
            .font(.caption).foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var adviceOfferBar: some View {
        HStack(spacing: 10) {
            Text("Want some actual thoughts on this?")
                .font(.caption).foregroundStyle(.white.opacity(0.55))
            Spacer()
            Button("Yes please") { Task { await vm.askForAdvice() } }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "#1D9E75"))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(hex: "#1D9E75").opacity(0.15))
                .clipShape(Capsule())
            Button("No thanks") {
                withAnimation { vm.showAdviceOffer = false }
            }
            .font(.caption).foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: — Reframe panel (Clear Your Head, built in)

    private var reframePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Thought reframe")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#7F77DD"))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Button { vm.showReframePanel = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            if vm.isReframing {
                HStack(spacing: 10) {
                    ProgressView().tint(Color(hex: "#7F77DD"))
                    Text("Finding another way to see this...")
                        .font(.caption).foregroundStyle(.white.opacity(0.5))
                }
            } else if !vm.reframeResult.isEmpty {
                Text(vm.reframeResult)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(3)
                    .padding(14)
                    .background(Color(hex: "#7F77DD").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    vm.showReframePanel = false
                    vm.showReframeOffer = false
                    inputFocused = true
                } label: {
                    Text("Back to venting")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#0f0f18"))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(hex: "#7F77DD").opacity(0.3)).frame(height: 1)
        }
    }

    // MARK: — Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if vm.inputText.isEmpty {
                    Text("Just say it...")
                        .foregroundStyle(.white.opacity(0.25))
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                }
                TextEditor(text: $vm.inputText)
                    .foregroundStyle(.white)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 36, maxHeight: 120)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .focused($inputFocused)
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(inputFocused ? 0.12 : 0.05), lineWidth: 1))

            Button {
                vm.send()
                inputFocused = false
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .white.opacity(0.2) : .white)
                    .frame(width: 36, height: 36)
                    .background(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.white.opacity(0.06) : Color(hex: "#7F77DD"))
                    .clipShape(Circle())
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isThinking)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color(hex: "#0f0f18"))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
        }
    }
}

// MARK: — Bubbles

struct VentBubble: View {
    let message: VentMessage
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            Text(message.content)
                .font(.body)
                .foregroundStyle(isUser ? .white : .white.opacity(0.85))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(isUser ? Color(hex: "#1c1c30") : Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(isUser ? 0.08 : 0.04), lineWidth: 0.5))
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

struct VentTypingIndicator: View {
    @State private var phase = 0
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(phase == i ? 0.55 : 0.18))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 48)
        }
        .onAppear { phase = 1 }
    }
}

// MARK: — Message model

struct VentMessage: Identifiable {
    let id      = UUID()
    let role:   VentRole
    let content: String
    enum VentRole { case user, assistant }
}

// MARK: — ViewModel

@MainActor
final class VentViewModel: ObservableObject {

    @Published var messages:         [VentMessage] = []
    @Published var inputText:        String        = ""
    @Published var isThinking:       Bool          = false
    @Published var showReframeOffer: Bool          = false
    @Published var showAdviceOffer:  Bool          = false
    @Published var showReframePanel: Bool          = false
    @Published var reframeResult:    String        = ""
    @Published var isReframing:      Bool          = false

    private let claude       = ClaudeService()
    private var messageCount = 0

    // Vent system prompt — just listens
    private let ventSystem = """
    You are in Vent Mode for Glow, a mental health app for teen girls.
    YOUR ONLY JOB: Listen and reflect. Never give advice.
    RULES:
    - Never say "have you tried", "maybe you could", "one thing that might help"
    - Never use therapy phrases: "I hear that you're feeling", "it sounds like", "that must be hard"
    - Short responses — 1 to 3 sentences max
    - Start with things like: "That's a lot.", "Oof.", "Yeah that's rough.", "That makes sense.", "Damn."
    - Ask one simple follow-up if natural
    - If crisis/self-harm mentioned, gently mention 988
    TONE: Wise older sister who listens. Not a therapist.
    """

    // Advice system — only when asked
    private let adviceSystem = """
    You are Glow. The user has been venting and now wants your thoughts.
    Give one honest, practical, direct thought. Under 50 words. 
    No bullet points. Speak like a smart older friend. No preamble.
    """

    // Reframe system — Clear Your Head built in
    private let reframeSystem = """
    You are Glow's thought reframe tool.
    The user has been venting. Based on what they said, identify their core negative thought.
    Respond with exactly:
    1. One line: the thought pattern name (plain English, not clinical)
    2. One line: a gentler, realistic way to see it
    3. One line: one tiny action they could take right now
    Keep the whole response under 80 words. Never use "cognitive distortion".
    """

    func startSession() {
        let openers = [
            "Go ahead. No advice, no fixes. Just say it.",
            "Nothing gets saved. What's going on?",
            "Just venting? Good. Let it out.",
            "No judgment here. What's on your mind?",
            "Say whatever you need to. I'm here.",
        ]
        messages.append(VentMessage(role: .assistant, content: openers.randomElement()!))
    }

    func clearSession() {
        messages         = []
        inputText        = ""
        isThinking       = false
        messageCount     = 0
        showReframeOffer = false
        showAdviceOffer  = false
        showReframePanel = false
        reframeResult    = ""
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        inputText        = ""
        isThinking       = true
        showReframeOffer = false
        showAdviceOffer  = false
        messageCount    += 1

        messages.append(VentMessage(role: .user, content: text))

        Task {
            let history = messages.dropLast().map {
                Message(role: $0.role == .user ? .user : .assistant, content: $0.content)
            }
            let reply = (try? await claude.send(
                userMessage:  text,
                history:      Array(history),
                systemPrompt: ventSystem
            )) ?? "Still here. Keep going."

            messages.append(VentMessage(role: .assistant, content: reply))
            isThinking = false

            // After 2 exchanges offer reframe, after 4 offer advice
            if messageCount == 2 {
                withAnimation { showReframeOffer = true }
            } else if messageCount == 4 {
                withAnimation { showAdviceOffer = true }
            }
        }
    }

    func startReframe() async {
        showReframeOffer = false
        showReframePanel = true
        isReframing      = true

        let summary = messages.filter { $0.role == .user }.map(\.content).joined(separator: ". ")
        reframeResult = (try? await claude.quick(
            prompt: "The user has been venting about: \(summary)",
            system: reframeSystem
        )) ?? "The thought: everything is going wrong.\nAnother way: this specific thing is hard — not everything.\nOne action: write down one thing that's actually okay right now."

        isReframing = false
    }

    func askForAdvice() async {
        showAdviceOffer = false
        isThinking      = true
        let summary = messages.filter { $0.role == .user }.map(\.content).joined(separator: ". ")
        let reply = (try? await claude.quick(
            prompt: "User vented about: \(summary). They've asked for thoughts.",
            system: adviceSystem
        )) ?? "Honestly? Trust your gut on this one. You already know more than you think."
        messages.append(VentMessage(role: .assistant, content: reply))
        isThinking = false
    }
}
