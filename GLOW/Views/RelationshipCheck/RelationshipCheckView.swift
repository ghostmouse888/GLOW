import SwiftUI
import Combine

// MARK: — Relationship Check
// Helps identify healthy vs draining relationship patterns
// Not alarmist — just asks questions worth thinking about

// MARK: — Models

enum RelationshipType: String, CaseIterable {
    case friendship  = "Friendship"
    case romantic    = "Romantic"
    case family      = "Family"
    case other       = "Other"

    var emoji: String {
        switch self {
        case .friendship: return "👯"
        case .romantic:   return "❤️"
        case .family:     return "🏠"
        case .other:      return "🤝"
        }
    }
}

struct RelationshipQuestion: Identifiable {
    let id        = UUID()
    let text:     String
    let redFlag:  Bool    // true = yes answer is a red flag
    var answer:   Bool? = nil
}

// MARK: — Main View

struct RelationshipCheckView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RelationshipCheckViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                switch vm.screen {
                case .home:   homeScreen
                case .quiz:   quizScreen
                case .result: resultScreen
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .navigationTitle("Relationship check")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: — Home

    private var homeScreen: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Text("❤️")
                    .font(.system(size: 48))
                Text("How is this relationship actually making you feel?")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Not how it should make you feel. How it actually does.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Relationship type picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Which relationship?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(RelationshipType.allCases, id: \.self) { type in
                        Button {
                            vm.relationshipType = type
                            vm.loadQuestions()
                            vm.screen = .quiz
                        } label: {
                            VStack(spacing: 8) {
                                Text(type.emoji)
                                    .font(.system(size: 30))
                                Text(type.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.separator), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Green flags info
            VStack(alignment: .leading, spacing: 12) {
                Text("Green flags in healthy relationships")
                    .font(.subheadline.weight(.semibold))
                ForEach(greenFlags, id: \.self) { flag in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "#1D9E75"))
                            .font(.subheadline)
                        Text(flag)
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.top, 8)
    }

    private let greenFlags = [
        "You feel safe to say no without fear",
        "Your feelings are taken seriously, even when they disagree",
        "You feel like yourself, not a version of yourself they'd prefer",
        "You leave interactions feeling energised, not drained",
        "Mistakes are worked through, not weaponised",
    ]

    // MARK: — Quiz

    private var quizScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button("← Back") { vm.screen = .home }
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#D4537E"))
                Spacer()
                if let type = vm.relationshipType {
                    Text("\(type.emoji) \(type.rawValue)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text("A few questions to think about")
                .font(.title2.weight(.semibold))
            Text("Answer honestly — this is just for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(vm.currentQuestions.indices, id: \.self) { i in
                    RelationshipQuestionCard(
                        question: vm.currentQuestions[i],
                        onAnswer: { answer in
                            vm.currentQuestions[i].answer = answer
                        }
                    )
                }
            }

            let answered = vm.currentQuestions.filter { $0.answer != nil }.count
            let total    = vm.currentQuestions.count

            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(Color(hex: "#D4537E"))
                    Text("Thinking about this...")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                Task { await vm.analyse() }
            } label: {
                Text(answered < total
                     ? "Answer all questions (\(answered)/\(total))"
                     : "See what Glow thinks")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(answered < total ? Color.gray : Color(hex: "#D4537E"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(answered < total || vm.isLoading)
        }
        .padding(.top, 8)
    }

    // MARK: — Result

    private var resultScreen: some View {
        VStack(spacing: 16) {
            HStack {
                Button("← Back") { vm.screen = .quiz }
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#D4537E"))
                Spacer()
            }

            // Overall reading
            VStack(spacing: 12) {
                Text(vm.resultEmoji)
                    .font(.system(size: 48))
                Text(vm.resultTitle)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(vm.resultSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Claude insight
            if !vm.claudeInsight.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.min.fill")
                            .foregroundStyle(Color(hex: "#EF9F27"))
                        Text("Glow says")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(vm.claudeInsight)
                        .font(.body)
                        .lineSpacing(3)
                }
                .padding(18)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Red flags found
            if !vm.redFlagsFound.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Worth paying attention to")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    ForEach(vm.redFlagsFound, id: \.self) { flag in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(Color(hex: "#EF9F27"))
                                .font(.subheadline)
                                .padding(.top, 1)
                            Text(flag)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "#FAEEDA"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // What this means
            VStack(alignment: .leading, spacing: 10) {
                Text("Remember")
                    .font(.subheadline.weight(.semibold))
                Text("This isn't a diagnosis of your relationship — it's questions worth sitting with. Only you know the full picture. If anything here resonated, it might be worth talking to Glow or someone you trust.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                vm.screen = .home
                vm.reset()
            } label: {
                Text("Check another relationship")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: "#D4537E"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#D4537E").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 8)
    }
}

// MARK: — Question Card

private struct RelationshipQuestionCard: View {
    let question: RelationshipQuestion
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.text)
                .font(.subheadline)
                .lineSpacing(2)

            HStack(spacing: 10) {
                ForEach([(true, "Yes"), (false, "No, not really")], id: \.1) { val, label in
                    Button { onAnswer(val) } label: {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(question.answer == val ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                question.answer == val
                                    ? (val == question.redFlag
                                        ? Color(hex: "#E24B4A")
                                        : Color(hex: "#1D9E75"))
                                    : Color(.tertiarySystemBackground)
                            )
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: — ViewModel

@MainActor
final class RelationshipCheckViewModel: ObservableObject {

    enum Screen { case home, quiz, result }
    @Published var screen:           Screen           = .home
    @Published var relationshipType: RelationshipType? = nil
    @Published var currentQuestions: [RelationshipQuestion] = []
    @Published var claudeInsight:    String           = ""
    @Published var redFlagsFound:    [String]         = []
    @Published var isLoading:        Bool             = false

    private let claude = ClaudeService()

    private let friendshipQuestions: [RelationshipQuestion] = [
        RelationshipQuestion(text: "Do you feel like you can be yourself around them, or do you filter yourself?", redFlag: false),
        RelationshipQuestion(text: "Do they put you down — even as a joke — in front of others?", redFlag: true),
        RelationshipQuestion(text: "Do you leave time with them feeling drained more often than energised?", redFlag: true),
        RelationshipQuestion(text: "Do they celebrate your wins genuinely, or does it feel competitive?", redFlag: false),
        RelationshipQuestion(text: "Do they make you feel guilty for spending time with other people?", redFlag: true),
        RelationshipQuestion(text: "Can you say no to them without it becoming a problem?", redFlag: false),
    ]

    private let romanticQuestions: [RelationshipQuestion] = [
        RelationshipQuestion(text: "Do you feel like you have to earn their good mood?", redFlag: true),
        RelationshipQuestion(text: "Do they respect it when you say no to something?", redFlag: false),
        RelationshipQuestion(text: "Do you feel anxious when you haven't heard from them, even briefly?", redFlag: true),
        RelationshipQuestion(text: "Have they ever made you feel stupid, ugly, or worthless — even once?", redFlag: true),
        RelationshipQuestion(text: "Do you feel safe to disagree with them without it escalating?", redFlag: false),
        RelationshipQuestion(text: "Do they check your phone, messages, or where you've been?", redFlag: true),
    ]

    private let familyQuestions: [RelationshipQuestion] = [
        RelationshipQuestion(text: "Do they make you feel guilty for having your own opinions?", redFlag: true),
        RelationshipQuestion(text: "Are you able to set basic limits without it becoming a huge conflict?", redFlag: false),
        RelationshipQuestion(text: "Do they compare you negatively to others (siblings, cousins, etc)?", redFlag: true),
        RelationshipQuestion(text: "Do you feel like your emotions are taken seriously in this relationship?", redFlag: false),
        RelationshipQuestion(text: "Do you feel responsible for managing their emotions?", redFlag: true),
    ]

    private let genericQuestions: [RelationshipQuestion] = [
        RelationshipQuestion(text: "Do you feel respected in this relationship?", redFlag: false),
        RelationshipQuestion(text: "Does this person make you feel worse about yourself regularly?", redFlag: true),
        RelationshipQuestion(text: "Can you be honest with them without it becoming an issue?", redFlag: false),
        RelationshipQuestion(text: "Do you feel like you give more than you receive?", redFlag: true),
        RelationshipQuestion(text: "Would you be happy if a friend had this same relationship?", redFlag: false),
    ]

    func loadQuestions() {
        switch relationshipType {
        case .friendship: currentQuestions = friendshipQuestions
        case .romantic:   currentQuestions = romanticQuestions
        case .family:     currentQuestions = familyQuestions
        default:          currentQuestions = genericQuestions
        }
    }

    var resultEmoji: String {
        let redCount = currentQuestions.filter {
            $0.redFlag && $0.answer == true ||
            !$0.redFlag && $0.answer == false
        }.count
        if redCount >= 4 { return "😔" }
        if redCount >= 2 { return "🤔" }
        return "💚"
    }

    var resultTitle: String {
        let redCount = currentQuestions.filter {
            $0.redFlag && $0.answer == true ||
            !$0.redFlag && $0.answer == false
        }.count
        if redCount >= 4 { return "This relationship sounds draining" }
        if redCount >= 2 { return "Some things worth thinking about" }
        return "This sounds mostly healthy"
    }

    var resultSubtitle: String {
        let redCount = currentQuestions.filter {
            $0.redFlag && $0.answer == true ||
            !$0.redFlag && $0.answer == false
        }.count
        if redCount >= 4 { return "Several patterns here that don't feel good. That matters." }
        if redCount >= 2 { return "A few things stood out that might be worth exploring." }
        return "No major red flags. You deserve to feel this good in all your relationships."
    }

    func analyse() async {
        isLoading = true

        // Find red flags
        redFlagsFound = currentQuestions.compactMap { q in
            guard q.redFlag && q.answer == true ||
                  !q.redFlag && q.answer == false else { return nil }
            return q.text
        }

        let type     = relationshipType?.rawValue ?? "relationship"
        let reds     = redFlagsFound.count
        let answers  = currentQuestions.map { "\($0.text): \($0.answer == true ? "Yes" : "No")" }.joined(separator: "\n")

        let prompt = "Relationship type: \(type). Concerning patterns found: \(reds). Answers:\n\(answers)"
        let system = """
        You are Glow, a warm companion for teen girls.
        Give 2 sentences about this relationship check.
        Be honest but gentle — not alarmist.
        If there are red flags, acknowledge them without catastrophising.
        If it's healthy, affirm it simply.
        Never tell them what to do. Just reflect what you see.
        """

        claudeInsight = (try? await claude.quick(prompt: prompt, system: system))
            ?? "Every relationship is complex, and you know this one better than anyone. What stands out to you most from these answers?"

        isLoading = false
        screen    = .result
    }

    func reset() {
        currentQuestions = []
        claudeInsight    = ""
        redFlagsFound    = []
        relationshipType = nil
    }

    // Load questions when type is set
    func setType(_ type: RelationshipType) {
        relationshipType = type
        loadQuestions()
        screen = .quiz
    }
}

