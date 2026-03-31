import SwiftUI
import Combine

// MARK: — Vibe Check
// Everyday situation checker — is this normal or off?
// Expanded from People Pleaser to cover all kinds of everyday situations

// MARK: — Situation Categories

struct VibeCategory: Identifiable {
    let id:         String
    let emoji:      String
    let title:      String
    let subtitle:   String
    let color:      Color
    let situations: [VibeSituation]
}

struct VibeSituation: Identifiable {
    let id      = UUID()
    let text:   String
    let followUp: [String]  // quick follow-up questions
}

let vibeCategories: [VibeCategory] = [

    VibeCategory(
        id: "friendship",
        emoji: "👯",
        title: "Friendship",
        subtitle: "Something felt off with a friend",
        color: Color(hex: "#7F77DD"),
        situations: [
            VibeSituation(text: "They said something that hurt but played it off as a joke",
                          followUp: ["Did they apologise?", "Has this happened before?", "Did it feel intentional?"]),
            VibeSituation(text: "I was left out of something and found out later",
                          followUp: ["Were you the only one left out?", "Did they explain why?", "Did they tell you directly?"]),
            VibeSituation(text: "They only reach out when they need something",
                          followUp: ["Do you feel heard when you talk?", "Have you told them how you feel?", "Do you feel drained after talking?"]),
            VibeSituation(text: "They shared something I told them in confidence",
                          followUp: ["Did they realise it was private?", "Did they apologise?", "Has it happened before?"]),
            VibeSituation(text: "I feel like I have to be in a certain mood to be around them",
                          followUp: ["Do you feel judged when you're sad?", "Do they make you feel like a burden?", "Are you your real self with them?"]),
            VibeSituation(text: "They get competitive or weird when good things happen to me",
                          followUp: ["Do they celebrate your wins?", "Do they compare themselves to you?", "Do you feel you have to downplay your wins?"]),
        ]
    ),

    VibeCategory(
        id: "romantic",
        emoji: "💕",
        title: "Relationship",
        subtitle: "Something felt weird with someone you like",
        color: Color(hex: "#D4537E"),
        situations: [
            VibeSituation(text: "They made me feel guilty for spending time with other people",
                          followUp: ["Did they say it directly or hint it?", "Did they apologise?", "Does this happen often?"]),
            VibeSituation(text: "They said something that made me feel bad about how I look",
                          followUp: ["Was it a joke or serious?", "Did it feel intentional?", "Have they said things like this before?"]),
            VibeSituation(text: "I feel anxious when I don't hear back from them quickly",
                          followUp: ["Have they ignored you before?", "Do they get annoyed when you don't reply fast?", "Does this feel new or has it always been this way?"]),
            VibeSituation(text: "I changed my plans for them and they didn't do the same for me",
                          followUp: ["Is this a pattern?", "Did they acknowledge you changed plans?", "Do you feel like you give more than you get?"]),
            VibeSituation(text: "They were fine with something when we talked about it but now they're not",
                          followUp: ["Did something change?", "Did they explain why?", "Do you feel confused about where you stand?"]),
            VibeSituation(text: "I feel like I have to be a certain way around them",
                          followUp: ["Do you filter how you act?", "Are you scared of how they'll react?", "Do you feel more relaxed when they're not around?"]),
        ]
    ),

    VibeCategory(
        id: "family",
        emoji: "🏠",
        title: "Family",
        subtitle: "Something at home didn't feel right",
        color: Color(hex: "#EF9F27"),
        situations: [
            VibeSituation(text: "I got blamed for something that wasn't my fault",
                          followUp: ["Did they listen to your side?", "Did they apologise?", "Does this happen often?"]),
            VibeSituation(text: "They compared me to a sibling or someone else",
                          followUp: ["Was it in front of others?", "Did it feel intentional?", "How did it make you feel about yourself?"]),
            VibeSituation(text: "I'm expected to manage their emotions",
                          followUp: ["Do you feel responsible for their mood?", "Do you hide things to keep the peace?", "Do you feel like you're walking on eggshells?"]),
            VibeSituation(text: "They read my messages or went through my things without asking",
                          followUp: ["Did they tell you they did it?", "Have they done it before?", "Do you feel like you have any privacy?"]),
            VibeSituation(text: "My feelings were dismissed or told I was overreacting",
                          followUp: ["Was it about something important to you?", "Did they try to understand?", "Does this happen a lot?"]),
        ]
    ),

    VibeCategory(
        id: "social",
        emoji: "📱",
        title: "Social situations",
        subtitle: "Something felt off in a group or online",
        color: Color(hex: "#1D9E75"),
        situations: [
            VibeSituation(text: "Someone made a comment about me in a group chat",
                          followUp: ["Did others defend you?", "Did the person apologise?", "Was it a joke or a dig?"]),
            VibeSituation(text: "I was talked over or ignored in a group conversation",
                          followUp: ["Did anyone notice?", "Did it feel deliberate?", "Has this happened before?"]),
            VibeSituation(text: "I was pressured to do something I wasn't comfortable with",
                          followUp: ["Did you feel safe to say no?", "Did they respect it when you said no?", "Were others pressuring you too?"]),
            VibeSituation(text: "Someone shared or reposted something of mine without asking",
                          followUp: ["Was it public content?", "Did it feel like an invasion?", "Did they take it down when asked?"]),
            VibeSituation(text: "I felt excluded from a group event or conversation",
                          followUp: ["Was it deliberate?", "Did anyone reach out to include you?", "Has this happened with this group before?"]),
        ]
    ),

    VibeCategory(
        id: "selfcheck",
        emoji: "🪞",
        title: "Self check",
        subtitle: "Something about how you're feeling",
        color: Color(hex: "#D85A30"),
        situations: [
            VibeSituation(text: "I said yes to something but immediately wanted to say no",
                          followUp: ["Did you feel pressured?", "Are you resentful about it?", "Could you have said no safely?"]),
            VibeSituation(text: "I apologised even though I didn't do anything wrong",
                          followUp: ["Is this a habit?", "Did you feel responsible for their reaction?", "Do you do this a lot?"]),
            VibeSituation(text: "I felt guilty for doing something that was completely fine",
                          followUp: ["Did someone make you feel guilty?", "Or did it come from inside?", "Would you judge a friend for doing the same?"]),
            VibeSituation(text: "I pretended to be okay when I wasn't",
                          followUp: ["Did you feel safe to be honest?", "Were you protecting someone?", "Do you feel like you can't show when you're not okay?"]),
            VibeSituation(text: "I felt bad about myself for no clear reason",
                          followUp: ["Did something trigger it?", "Is it a one-off or been going on a while?", "Did you compare yourself to someone?"]),
        ]
    ),
]

// MARK: — Main View

struct VibeCheckView: View {

    @StateObject private var vm = VibeCheckViewModel()

    var body: some View {
        Group {
            switch vm.screen {
            case .home:       homeScreen
            case .questions:  questionsScreen
            case .result:     resultScreen
            }
        }
        .navigationTitle("Vibe check")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: — Home

    private var homeScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // Header
                VStack(spacing: 10) {
                    Text("✅")
                        .font(.system(size: 48))
                    Text("Something felt off?")
                        .font(.title2.weight(.semibold))
                    Text("Pick the situation. Glow will help you figure out if your instincts are right.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Category grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(vibeCategories) { category in
                        Button {
                            vm.selectedCategory = category
                            vm.screen = .questions
                        } label: {
                            VStack(spacing: 8) {
                                Text(category.emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 56, height: 56)
                                    .background(category.color.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                Text(category.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(category.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(category.color.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Reminder
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Your answers stay private and are never saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .padding(.top, 8)
        }
    }

    // MARK: — Questions

    private var questionsScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                guard let cat = vm.selectedCategory else {
                    return AnyView(EmptyView())
                }
                return AnyView(VStack(alignment: .leading, spacing: 20) {

                    // Back
                    Button("← Categories") { vm.screen = .home }
                        .font(.subheadline)
                        .foregroundStyle(cat.color)

                    // Category header
                    HStack(spacing: 12) {
                        Text(cat.emoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cat.title).font(.title2.weight(.semibold))
                            Text("Pick what happened")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    // Situation picker
                    VStack(spacing: 8) {
                        ForEach(cat.situations) { situation in
                            Button {
                                vm.selectedSituation = situation
                                vm.answers = []
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading) {
                                        Text(situation.text)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    if vm.selectedSituation?.id == situation.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(cat.color)
                                    }
                                }
                                .padding(14)
                                .background(vm.selectedSituation?.id == situation.id
                                    ? cat.color.opacity(0.08) : Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(vm.selectedSituation?.id == situation.id
                                        ? cat.color : Color(.separator), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Follow-up questions
                    if let sit = vm.selectedSituation {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("A few more questions")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            ForEach(sit.followUp.indices, id: \.self) { i in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(sit.followUp[i])
                                        .font(.subheadline)
                                    HStack(spacing: 8) {
                                        ForEach(["Yes", "No", "Not sure"], id: \.self) { opt in
                                            let answered = vm.answers.count > i ? vm.answers[i] : nil
                                            Button { vm.setAnswer(i, opt) } label: {
                                                Text(opt)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(answered == opt ? .white : .primary)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(answered == opt
                                                        ? cat.color : Color(.tertiarySystemBackground))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(14)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        if vm.isLoading {
                            HStack(spacing: 10) {
                                ProgressView().tint(cat.color)
                                Text("Checking the vibe...")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if vm.answers.count == sit.followUp.count {
                            Button {
                                Task { await vm.checkVibe() }
                            } label: {
                                Text("Check the vibe")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(cat.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(vm.isLoading)
                        }
                    }
                })
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .padding(.top, 8)
        }
    }

    // MARK: — Result

    private var resultScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                guard let cat = vm.selectedCategory else {
                    return AnyView(EmptyView())
                }
                return AnyView(VStack(spacing: 16) {

                    Button("← Back") { vm.screen = .questions }
                        .font(.subheadline)
                        .foregroundStyle(cat.color)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Vibe rating
                    VStack(spacing: 10) {
                        Text(vm.vibeEmoji)
                            .font(.system(size: 52))
                        Text(vm.vibeTitle)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                        Text(vm.vibeSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Claude's take
                    if !vm.claudeResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "sun.min.fill")
                                    .foregroundStyle(Color(hex: "#EF9F27"))
                                Text("Glow says")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Text(vm.claudeResponse)
                                .font(.body)
                                .lineSpacing(3)
                        }
                        .padding(18)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Situation they described
                    if let sit = vm.selectedSituation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What you described")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text(sit.text)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(cat.color.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // What to remember
                    if !vm.takeaway.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Worth remembering")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text(vm.takeaway)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineSpacing(2)
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        vm.reset()
                    } label: {
                        Text("Check another situation")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(cat.color)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cat.color.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                })
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .padding(.top, 8)
        }
    }
}

// MARK: — ViewModel

@MainActor
final class VibeCheckViewModel: ObservableObject {

    enum Screen { case home, questions, result }
    @Published var screen:             Screen          = .home
    @Published var selectedCategory:   VibeCategory?   = nil
    @Published var selectedSituation:  VibeSituation?  = nil
    @Published var answers:            [String]        = []
    @Published var claudeResponse:     String          = ""
    @Published var vibeEmoji:          String          = ""
    @Published var vibeTitle:          String          = ""
    @Published var vibeSubtitle:       String          = ""
    @Published var takeaway:           String          = ""
    @Published var isLoading:          Bool            = false

    private let claude = ClaudeService()

    func setAnswer(_ index: Int, _ answer: String) {
        if answers.count <= index {
            answers.append(contentsOf: Array(repeating: "", count: index - answers.count + 1))
        }
        answers[index] = answer
    }

    func checkVibe() async {
        guard let cat = selectedCategory,
              let sit = selectedSituation else { return }
        isLoading = true

        let qaText = zip(sit.followUp, answers)
            .map { "\($0): \($1)" }
            .joined(separator: "\n")

        let prompt = "Category: \(cat.title). Situation: \(sit.text)\nAnswers:\n\(qaText)"
        let system = """
        You are Glow, a warm companion for teen girls.
        The user has described a situation and answered follow-up questions.
        
        First decide if their instincts are right:
        - "Off vibe" — something genuinely wasn't okay here
        - "Worth noting" — mixed signals, worth paying attention
        - "You're good" — this seems like it's okay
        
        Then give 2 sentences:
        1. Validate what they picked up on — or reassure them if it's fine
        2. One practical thought about what to do or think about next
        
        Be direct and specific. No generic advice. No toxic positivity.
        Speak like a wise older sister, not a therapist.
        """

        let response = (try? await claude.quick(prompt: prompt, system: system))
            ?? "Your instincts picked up on something real here. Trust that — feelings like this are usually pointing to something worth paying attention to."

        // Parse vibe level from response
        let lower = response.lowercased()
        if lower.contains("off vibe") || lower.contains("wasn't okay") || lower.contains("red flag") {
            vibeEmoji   = "🚨"
            vibeTitle   = "Off vibe"
            vibeSubtitle = "Your instincts were right. Something wasn't okay here."
        } else if lower.contains("worth noting") || lower.contains("mixed") || lower.contains("pay attention") {
            vibeEmoji   = "🤔"
            vibeTitle   = "Worth noting"
            vibeSubtitle = "Not an emergency but worth keeping an eye on."
        } else {
            vibeEmoji   = "✅"
            vibeTitle   = "You're good"
            vibeSubtitle = "This one seems okay. Your feelings are valid either way."
        }

        claudeResponse = response
        takeaway = cat.id == "selfcheck"
            ? "You noticed something about yourself — that takes awareness. That's not a small thing."
            : "Your gut is one of your best tools. If something felt off, it usually was."

        isLoading = false
        screen    = .result
    }

    func reset() {
        screen            = .home
        selectedCategory  = nil
        selectedSituation = nil
        answers           = []
        claudeResponse    = ""
        vibeEmoji         = ""
        vibeTitle         = ""
        vibeSubtitle      = ""
        takeaway          = ""
    }
}

// MARK: — Color extension
