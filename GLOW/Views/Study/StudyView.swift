import SwiftUI
import Combine

// MARK: — Study
// Full AI homework and schoolwork assistant
// Explains concepts, checks answers, helps with essays, quizzes the user

// MARK: — Study Mode

enum StudyMode: String, CaseIterable, Identifiable {
    case explain   = "Explain this"
    case homework  = "Help with homework"
    case essay     = "Essay help"
    case quiz      = "Quiz me"
    case formula   = "Formulas & facts"
    case summarise = "Summarise this"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .explain:   return "💡"
        case .homework:  return "📝"
        case .essay:     return "✍️"
        case .quiz:      return "🧠"
        case .formula:   return "🔢"
        case .summarise: return "📖"
        }
    }

    var subtitle: String {
        switch self {
        case .explain:   return "Understand any concept"
        case .homework:  return "Work through a problem"
        case .essay:     return "Structure, intro, argument"
        case .quiz:      return "Test what you know"
        case .formula:   return "Quick reference"
        case .summarise: return "Paste text to summarise"
        }
    }

    var placeholder: String {
        switch self {
        case .explain:   return "What do you need explained? e.g. photosynthesis, the French Revolution, Pythagoras..."
        case .homework:  return "Paste your question or describe what you're stuck on..."
        case .essay:     return "What's your essay topic? Paste your draft or just the title..."
        case .quiz:      return "What subject or topic do you want to be quizzed on?"
        case .formula:   return "What formula or fact do you need? e.g. area of a circle, speed of light..."
        case .summarise: return "Paste the text you want summarised..."
        }
    }

    var color: Color {
        switch self {
        case .explain:   return Color(hex: "#EF9F27")
        case .homework:  return Color(hex: "#1D9E75")
        case .essay:     return Color(hex: "#7F77DD")
        case .quiz:      return Color(hex: "#D4537E")
        case .formula:   return Color(hex: "#378ADD")
        case .summarise: return Color(hex: "#D85A30")
        }
    }

    var systemPrompt: String {
        let base = "You are Glow's study assistant for a teen student. Be clear, direct, and encouraging."
        switch self {
        case .explain:
            return "\(base) Explain the concept in plain language a teen can understand. Use an analogy if it helps. Break it into steps. Keep it under 200 words unless they need more detail."
        case .homework:
            return "\(base) Help the student work through their homework problem. Don't just give the answer — explain the method so they can do similar problems themselves. Show your working."
        case .essay:
            return "\(base) Help with essay structure, arguments, introductions, and conclusions. If they give a draft, give specific feedback. If they give a topic, outline a structure. Be constructive and specific."
        case .quiz:
            return "\(base) Quiz the student on their topic. Ask one question at a time. Wait for their answer before giving the next question. Tell them if they're right or wrong and explain why. Adjust difficulty based on how they do."
        case .formula:
            return "\(base) Give the formula or fact clearly with units. Explain what each part means. Give a simple example of how to use it. Format clearly."
        case .summarise:
            return "\(base) Summarise the text clearly and concisely. Pull out the key points as a short paragraph. Then list 3-5 bullet points of the most important facts or ideas. Keep language simple."
        }
    }
}

// MARK: — Subject chips

let commonSubjects = [
    "Maths", "English", "Science", "History", "Geography",
    "Biology", "Chemistry", "Physics", "French", "Spanish",
    "Art", "Music", "Computing", "Economics", "Psychology",
]

// MARK: — Main View

struct StudyView: View {

    @StateObject private var vm = StudyViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if vm.activeMode == nil {
                modePickerView
            } else {
                activeStudyView
            }
        }
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            if vm.activeMode != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("End session") {
                        vm.endSession()
                    }
                    .foregroundStyle(Color(hex: "#D4537E"))
                }
            }
        }
    }

    // MARK: — Mode picker

    private var modePickerView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 8) {
                    Text("📚")
                        .font(.system(size: 48))
                    Text("What do you need help with?")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text("Glow can explain, quiz, write, and work through anything school-related.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Mode grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(StudyMode.allCases) { mode in
                        Button {
                            vm.activeMode = mode
                        } label: {
                            VStack(spacing: 8) {
                                Text(mode.emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 52, height: 52)
                                    .background(mode.color.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                Text(mode.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(mode.color.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Quick subjects
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick subject start")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(commonSubjects, id: \.self) { subject in
                                Button {
                                    vm.quickStartSubject(subject)
                                } label: {
                                    Text(subject)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemBackground))
                                        .clipShape(Capsule())
                                        .overlay(Capsule()
                                            .stroke(Color(.separator), lineWidth: 0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .padding(.top, 8)
        }
    }

    // MARK: — Active study session

    private var activeStudyView: some View {
        VStack(spacing: 0) {
            guard let mode = vm.activeMode else { return AnyView(EmptyView()) }

            return AnyView(VStack(spacing: 0) {

                // Mode banner
                HStack(spacing: 10) {
                    Text(mode.emoji).font(.system(size: 18))
                    Text(mode.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode.color)
                    Spacer()
                    if !vm.subject.isEmpty {
                        Text(vm.subject)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(.separator)).frame(height: 0.5)
                }

                // Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {

                            // Subject picker if not set
                            if vm.subject.isEmpty && vm.messages.count <= 1 {
                                subjectPicker(mode: mode)
                            }

                            ForEach(vm.messages) { msg in
                                StudyBubble(message: msg, modeColor: mode.color)
                                    .id(msg.id)
                            }
                            if vm.isThinking {
                                StudyThinkingIndicator(color: mode.color).id("thinking")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        withAnimation {
                            if let lastId = vm.messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            } else {
                                proxy.scrollTo("thinking", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input
                HStack(alignment: .bottom, spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        if vm.inputText.isEmpty {
                            Text(mode.placeholder)
                                .foregroundStyle(.secondary)
                                .font(.body)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                        }
                        TextEditor(text: $vm.inputText)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 36, maxHeight: 140)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .focused($inputFocused)
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(inputFocused
                            ? mode.color.opacity(0.4) : Color(.separator),
                                lineWidth: inputFocused ? 1.5 : 0.5))

                    Button {
                        Task { await vm.send() }
                        inputFocused = false
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray : mode.color)
                            .clipShape(Circle())
                    }
                    .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isThinking)
                    .animation(.easeInOut(duration: 0.15), value: vm.inputText.isEmpty)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(alignment: .top) {
                    Rectangle().fill(Color(.separator)).frame(height: 0.5)
                }
            })
        }
    }

    private func subjectPicker(mode: StudyMode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What subject?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(commonSubjects, id: \.self) { subject in
                        Button { vm.subject = subject } label: {
                            Text(subject)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(vm.subject == subject ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(vm.subject == subject
                                    ? (vm.activeMode?.color ?? Color.gray)
                                    : Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: — Study Bubble

struct StudyBubble: View {
    let message:   StudyMessage
    let modeColor: Color
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isUser {
                // Glow avatar
                ZStack {
                    Circle().fill(modeColor.opacity(0.15)).frame(width: 28, height: 28)
                    Text("✨").font(.system(size: 13))
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser
                        ? modeColor.opacity(0.1) : Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(isUser
                            ? modeColor.opacity(0.3) : Color(.separator),
                                lineWidth: 0.5))
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }

            if isUser {
                Circle()
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 28, height: 28)
                    .overlay(Text("👤").font(.system(size: 13)))
            }
        }
    }
}

struct StudyThinkingIndicator: View {
    let color: Color
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 28, height: 28)
                Text("✨").font(.system(size: 13))
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(color.opacity(phase == i ? 0.8 : 0.2))
                        .frame(width: 7, height: 7)
                        .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .onAppear { phase = 1 }
    }
}

// MARK: — Message model

struct StudyMessage: Identifiable {
    let id      = UUID()
    let role:   StudyRole
    let content: String
    enum StudyRole { case user, assistant }
}

// MARK: — ViewModel

@MainActor
final class StudyViewModel: ObservableObject {

    @Published var activeMode: StudyMode?     = nil
    @Published var messages:   [StudyMessage] = []
    @Published var inputText:  String         = ""
    @Published var isThinking: Bool           = false
    @Published var subject:    String         = ""

    private let claude = ClaudeService()

    func quickStartSubject(_ subject: String) {
        self.subject    = subject
        self.activeMode = .explain
        let opener = StudyMessage(
            role: .assistant,
            content: "Hey! I'm ready to help with \(subject). What do you need — an explanation, homework help, or want me to quiz you?"
        )
        messages = [opener]
    }

    func endSession() {
        activeMode = nil
        messages   = []
        inputText  = ""
        subject    = ""
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking, let mode = activeMode else { return }

        inputText  = ""
        isThinking = true
        messages.append(StudyMessage(role: .user, content: text))

        let history = messages.dropLast().map {
            Message(role: $0.role == .user ? .user : .assistant, content: $0.content)
        }

        let subjectContext = subject.isEmpty ? "" : " The student is studying \(subject)."
        let system = mode.systemPrompt + subjectContext

        let reply = (try? await claude.send(
            userMessage:  text,
            history:      Array(history),
            systemPrompt: system
        )) ?? "I didn't quite catch that — could you rephrase the question?"

        messages.append(StudyMessage(role: .assistant, content: reply))
        isThinking = false
    }
}
