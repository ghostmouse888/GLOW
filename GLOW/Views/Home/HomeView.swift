import SwiftUI

// MARK: — Main App Shell

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home",     systemImage: "house.fill")   }.tag(0)
            ChatView()
                .tabItem { Label("Ask Glow", systemImage: "sun.min.fill") }.tag(1)
            StudyView()
                .tabItem { Label("Study",    systemImage: "book.fill")    }.tag(2)
            ProfileView()
                .tabItem { Label("Me",       systemImage: "person.fill")  }.tag(3)
        }
        .accentColor(Color(hex: "#EF9F27"))
    }
}

// MARK: — Dashboard

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMood: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    moodSection
                    everythingSection
                }
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: — Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeOfDayGreeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Hey \(appState.userName) 👋")
                        .font(.title.weight(.semibold))
                    if appState.streakDays > 0 {
                        Text(streakMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "#EF9F27"))
                    }
                }
                Spacer()
                // Glow sun logo — pulses gently
                GlowSunIcon()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }

    private var timeOfDayGreeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var streakMessage: String {
        switch appState.streakDays {
        case 1:       return "First day — great start 🌱"
        case 2...4:   return "\(appState.streakDays) days in a row — keep it up 🔥"
        case 5...9:   return "\(appState.streakDays) days strong — you're on a roll 🌟"
        case 10...29: return "\(appState.streakDays) days — this is becoming a habit 💪"
        default:      return "\(appState.streakDays) days — seriously impressive ✨"
        }
    }

    // MARK: — Mood Picker

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling right now?")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 0) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: selectedMood == mood
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedMood == mood {
                                selectedMood = nil // deselect on tap
                            } else {
                                selectedMood = mood
                                appState.recordCheckIn(mood: mood, energy: 5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .padding(.top, 8)
    }

    // MARK: — Smart Suggestions

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedMood != nil ? "Suggested for you" : "Good place to start")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                if let mood = selectedMood {
                    Text("based on feeling \(mood.label.lowercased())")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(suggestions(for: selectedMood)) { item in
                    NavigationLink(destination: item.destination) {
                        SuggestedCard(item: item, mood: selectedMood)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.25), value: selectedMood)
    }

    // MARK: — Everything Row

    private var everythingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Everything")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(features) { item in
                        NavigationLink(destination: item.destination) {
                            EverythingPill(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .padding(.top, 8)
    }
}

// MARK: — Mood Button

struct MoodButton: View {
    let mood:       Mood
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: isSelected ? 32 : 26))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                Text(mood.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? moodColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? moodColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    private var moodColor: Color {
        switch mood {
        case .great:   return Color(hex: "#1D9E75")
        case .okay:    return Color(hex: "#EF9F27")
        case .anxious: return Color(hex: "#7F77DD")
        case .low:     return Color(hex: "#378ADD")
        case .angry:   return Color(hex: "#D85A30")
        }
    }
}

// MARK: — Suggested Card

struct SuggestedCard: View {
    let item: FeatureItem
    let mood: Mood?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.iconBg)
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .foregroundStyle(item.iconColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(contextualSubtitle(for: item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.iconColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func contextualSubtitle(for item: FeatureItem) -> String {
        guard let mood = mood else { return item.subtitle }
        switch (item.id, mood) {
        case ("breathe", .anxious):  return "Breathing helps calm anxiety fast"
        case ("refresh", .anxious):  return "Flip that worried thought around"
        case ("chat",    .low):      return "Talk through how you're feeling"
        case ("move",    .low):      return "Gentle movement lifts your mood"
        case ("chat",    .angry):    return "Let it out — I'm here to listen"
        case ("move",    .angry):    return "Movement is the best anger release"
        case ("wins",    .great):    return "Log this great feeling — remember it"
        case ("focus",   .great):    return "Great mood = great focus window"
        case ("sleep",   .okay):     return "Wind down and get a good rest"
        case ("move",    .okay):     return "A little movement keeps things good"
        default: return item.subtitle
        }
    }
}

// MARK: — Everything Pill

struct EverythingPill: View {
    let item: FeatureItem

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(item.iconBg)
                    .frame(width: 52, height: 52)
                Text(item.emoji)
                    .font(.system(size: 24))
            }
            Text(item.shortTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 60)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

// MARK: — Glow Sun Icon (animated)

struct GlowSunIcon: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#EF9F27").opacity(0.2))
                .frame(width: 52, height: 52)
                .scaleEffect(pulsing ? 1.12 : 1.0)
            Circle()
                .fill(Color(hex: "#EF9F27"))
                .frame(width: 42, height: 42)
            Image(systemName: "sun.min.fill")
                .foregroundStyle(.white)
                .font(.system(size: 20))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

// MARK: — Feature Model

struct FeatureItem: Identifiable {
    let id:         String
    let title:      String
    let shortTitle: String
    let subtitle:   String
    let emoji:      String
    let icon:       String
    let iconBg:     Color
    let iconColor:  Color
    let destination: AnyView
}

// MARK: — Feature Registry
// All 9 features defined in one place — add new features here

let features: [FeatureItem] = [
    FeatureItem(
        id: "chat", title: "Ask Glow", shortTitle: "Glow",
        subtitle: "Talk to your AI companion",
        emoji: "💬", icon: "sun.min.fill",
        iconBg: Color(hex: "#FAEEDA"), iconColor: Color(hex: "#EF9F27"),
        destination: AnyView(ChatView())
    ),
    FeatureItem(
        id: "vent", title: "Vent", shortTitle: "Vent",
        subtitle: "Say it. Then maybe reframe it.",
        emoji: "💭", icon: "bubble.left.fill",
        iconBg: Color(hex: "#1a1a2e"), iconColor: Color.white.opacity(0.7),
        destination: AnyView(VentView())
    ),
    FeatureItem(
        id: "vibecheck", title: "Vibe Check", shortTitle: "Vibe",
        subtitle: "Did that feel off? Check it.",
        emoji: "🩷", icon: "heart.circle.fill",
        iconBg: Color(hex: "#FBEAF0"), iconColor: Color(hex: "#D4537E"),
        destination: AnyView(VibeCheckView())
    ),
    FeatureItem(
        id: "redflag", title: "Red Flag Check", shortTitle: "Red Flags",
        subtitle: "Healthy or draining?",
        emoji: "❤️", icon: "person.2.circle.fill",
        iconBg: Color(hex: "#FBEAF0"), iconColor: Color(hex: "#D4537E"),
        destination: AnyView(RelationshipCheckView())
    ),
    FeatureItem(
        id: "breathe", title: "Just Breathe", shortTitle: "Breathe",
        subtitle: "Calm down fast",
        emoji: "🫁", icon: "wind",
        iconBg: Color(hex: "#E1F5EE"), iconColor: Color(hex: "#1D9E75"),
        destination: AnyView(BreatheView())
    ),
    FeatureItem(
        id: "trainer", title: "Facial Training", shortTitle: "Face",
        subtitle: "15 face exercises",
        emoji: "📷", icon: "camera.fill",
        iconBg: Color(hex: "#E1F5EE"), iconColor: Color(hex: "#1D9E75"),
        destination: AnyView(FaceTrainerView())
    ),
    FeatureItem(
        id: "sleep", title: "Sleep", shortTitle: "Sleep",
        subtitle: "Track + wind down",
        emoji: "🌙", icon: "moon.fill",
        iconBg: Color(hex: "#EEEDFE"), iconColor: Color(hex: "#7F77DD"),
        destination: AnyView(SleepTrackerView())
    ),
    FeatureItem(
        id: "study", title: "Study", shortTitle: "Study",
        subtitle: "Homework & schoolwork help",
        emoji: "🎯", icon: "book.fill",
        iconBg: Color(hex: "#FAEEDA"), iconColor: Color(hex: "#EF9F27"),
        destination: AnyView(StudyView())
    ),
    FeatureItem(
        id: "wins", title: "Wins", shortTitle: "Wins",
        subtitle: "Celebrate good moments",
        emoji: "⭐", icon: "star.fill",
        iconBg: Color(hex: "#FAEEDA"), iconColor: Color(hex: "#EF9F27"),
        destination: AnyView(WinsView())
    ),
    FeatureItem(
        id: "cycle", title: "Cycle Tracker", shortTitle: "Cycle",
        subtitle: "Connect mood to your cycle",
        emoji: "🌙", icon: "moon.circle.fill",
        iconBg: Color(hex: "#FBEAF0"), iconColor: Color(hex: "#D4537E"),
        destination: AnyView(CycleMoodTrackerView())
    ),
    FeatureItem(
        id: "bodycheck", title: "Energy Check", shortTitle: "Energy",
        subtitle: "Tune into how you feel",
        emoji: "⚡", icon: "figure.stand",
        iconBg: Color(hex: "#FAECE7"), iconColor: Color(hex: "#D85A30"),
        destination: AnyView(BodyCheckView())
    ),
]

// MARK: — Profile View (placeholder)

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color(hex: "#EF9F27")).frame(width: 56, height: 56)
                            Text(appState.userName.prefix(1).uppercased())
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.userName).font(.headline)
                            Text("\(appState.streakDays) day streak")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("My stats") {
                    LabeledContent("Total sessions", value: "\(appState.moodHistory.count)")
                    LabeledContent("Current streak", value: "\(appState.streakDays) days")
                    LabeledContent("Most common mood", value: mostCommonMood)
                }

                Section {
                    Button("Reset onboarding", role: .destructive) {
                        appState.hasCompletedOnboarding = false
                    }
                }
            }
            .navigationTitle("Me")
        }
    }

    private var mostCommonMood: String {
        let counts = Dictionary(grouping: appState.moodHistory, by: \.mood)
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key.label ?? "—"
    }
}

// MARK: — Color helper (if not already in project)

