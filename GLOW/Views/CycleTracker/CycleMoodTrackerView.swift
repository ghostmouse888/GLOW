import SwiftUI
import Combine

// MARK: — Cycle Mood Tracker
// Logs period phases and correlates with mood entries
// Claude explains hormonal connections without medical advice

// MARK: — Models

enum CyclePhase: String, CaseIterable, Codable {
    case period      = "Period"
    case follicular  = "Follicular"
    case ovulation   = "Ovulation"
    case luteal      = "Luteal"

    var emoji: String {
        switch self {
        case .period:     return "🔴"
        case .follicular: return "🌱"
        case .ovulation:  return "✨"
        case .luteal:     return "🌙"
        }
    }

    var color: Color {
        switch self {
        case .period:     return Color(hex: "#E24B4A")
        case .follicular: return Color(hex: "#1D9E75")
        case .ovulation:  return Color(hex: "#EF9F27")
        case .luteal:     return Color(hex: "#7F77DD")
        }
    }

    var daysRange: String {
        switch self {
        case .period:     return "Days 1-5"
        case .follicular: return "Days 6-13"
        case .ovulation:  return "Days 14-16"
        case .luteal:     return "Days 17-28"
        }
    }

    var description: String {
        switch self {
        case .period:
            return "Oestrogen and progesterone are at their lowest. Fatigue, cramps, and low mood are completely normal."
        case .follicular:
            return "Oestrogen is rising. Energy, focus, and mood tend to improve. A great time for social activities and new projects."
        case .ovulation:
            return "Oestrogen peaks. Many people feel their most energetic, confident, and social around this time."
        case .luteal:
            return "Progesterone rises then falls. PMS symptoms like irritability, bloating, and anxiety can occur in the second half."
        }
    }

    var commonMoods: [String] {
        switch self {
        case .period:     return ["Tired", "Low", "Crampy", "Irritable", "Withdrawn"]
        case .follicular: return ["Energetic", "Optimistic", "Focused", "Social", "Creative"]
        case .ovulation:  return ["Confident", "Happy", "Outgoing", "Attractive", "Productive"]
        case .luteal:     return ["Anxious", "Emotional", "Bloated", "Sensitive", "Craving"]
        }
    }
}

struct CycleEntry: Identifiable, Codable {
    let id:    UUID
    let date:  Date
    let phase: CyclePhase
    let notes: String

    init(phase: CyclePhase, notes: String = "") {
        self.id    = UUID()
        self.date  = Date()
        self.phase = phase
        self.notes = notes
    }
}

// MARK: — Store

final class CycleStore: ObservableObject {
    @Published var entries: [CycleEntry] = []

    init() { load() }

    var todayEntry: CycleEntry? {
        entries.first {
            Calendar.current.isDateInToday($0.date)
        }
    }

    var currentPhase: CyclePhase? { todayEntry?.phase }

    func logToday(phase: CyclePhase, notes: String = "") {
        entries.removeAll { Calendar.current.isDateInToday($0.date) }
        entries.append(CycleEntry(phase: phase, notes: notes))
        entries.sort { $0.date < $1.date }
        persist()
    }

    // Last 28 days
    var recentEntries: [CycleEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: Date())!
        return entries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    // Most common phase per mood
    func commonPhase(for mood: String) -> CyclePhase? {
        let matching = entries.filter { $0.notes.lowercased().contains(mood.lowercased()) }
        let counts   = Dictionary(grouping: matching, by: \.phase).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "glow_cycle_entries")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "glow_cycle_entries"),
              let saved = try? JSONDecoder().decode([CycleEntry].self, from: data)
        else { return }
        entries = saved
    }
}

// MARK: — Main View

struct CycleMoodTrackerView: View {

    @StateObject private var store = CycleStore()
    @StateObject private var vm    = CycleViewModel()
    @State private var showLogger  = false
    @State private var selectedPhase: CyclePhase? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                todayCard
                phaseGuide
                if !store.recentEntries.isEmpty { recentLog }
                claudeInsightCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .navigationTitle("Cycle tracker")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .onAppear { Task { await vm.fetchInsight(store: store) } }
        .sheet(isPresented: $showLogger, onDismiss: {
            Task { await vm.fetchInsight(store: store) }
        }) {
            PhaseLoggerSheet(store: store)
        }
    }

    // MARK: — Today card

    private var todayCard: some View {
        VStack(spacing: 0) {
            if let phase = store.currentPhase {
                // Phase logged
                HStack(spacing: 14) {
                    Text(phase.emoji)
                        .font(.system(size: 40))
                        .frame(width: 64, height: 64)
                        .background(phase.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(phase.rawValue + " phase")
                            .font(.title2.weight(.semibold))
                        Text(phase.daysRange)
                            .font(.caption)
                            .foregroundStyle(phase.color)
                    }
                    Spacer()
                    Button { showLogger = true } label: {
                        Text("Edit")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(phase.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(phase.color.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(18)

                Divider().padding(.horizontal, 18)

                Text(phase.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(18)

                // Common moods for this phase
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(phase.commonMoods, id: \.self) { mood in
                            Text(mood)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(phase.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(phase.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }

            } else {
                // Not logged
                VStack(spacing: 14) {
                    Text("🌙")
                        .font(.system(size: 40))
                    Text("Where are you in your cycle today?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Logging your phase helps Glow connect your moods to your cycle.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button { showLogger = true } label: {
                        Text("Log today's phase")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#D4537E"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(24)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: — Phase guide

    private var phaseGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The 4 phases")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ForEach(CyclePhase.allCases, id: \.self) { phase in
                Button {
                    withAnimation {
                        selectedPhase = selectedPhase == phase ? nil : phase
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Text(phase.emoji).font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phase.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(phase.daysRange)
                                    .font(.caption)
                                    .foregroundStyle(phase.color)
                            }
                            Spacer()
                            Image(systemName: selectedPhase == phase
                                  ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)

                        if selectedPhase == phase {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(phase.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    ForEach(phase.commonMoods.prefix(3), id: \.self) { mood in
                                        Text(mood)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(phase.color)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(phase.color.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                    }
                }
                .buttonStyle(.plain)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedPhase == phase
                            ? phase.color.opacity(0.4) : Color(.separator),
                            lineWidth: selectedPhase == phase ? 1.5 : 0.5))
            }
        }
    }

    // MARK: — Recent log

    private var recentLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ForEach(store.recentEntries.suffix(7).reversed()) { entry in
                HStack(spacing: 12) {
                    Text(entry.phase.emoji).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.phase.rawValue)
                            .font(.subheadline.weight(.medium))
                        Text(relativeDate(entry.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !entry.notes.isEmpty {
                        Text(entry.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button { showLogger = true } label: {
                Label("Log today", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: "#D4537E"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#D4537E").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    // MARK: — Claude insight

    private var claudeInsightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sun.min.fill")
                    .foregroundStyle(Color(hex: "#EF9F27"))
                Text("Glow's take")
                    .font(.subheadline.weight(.semibold))
            }

            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(Color(hex: "#EF9F27")).scaleEffect(0.8)
                    Text("Looking at your patterns...")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            } else if !vm.insight.isEmpty {
                Text(vm.insight)
                    .font(.body)
                    .lineSpacing(3)
            } else {
                Text("Log your phase for a few days to see your personal patterns.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: — Phase Logger Sheet

struct PhaseLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: CycleStore
    @State private var selectedPhase: CyclePhase? = nil
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Where are you today?")
                    .font(.title2.weight(.semibold))
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(CyclePhase.allCases, id: \.self) { phase in
                        Button {
                            selectedPhase = phase
                        } label: {
                            HStack(spacing: 14) {
                                Text(phase.emoji).font(.system(size: 28))
                                    .frame(width: 52, height: 52)
                                    .background(phase.color.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(phase.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(phase.daysRange)
                                        .font(.caption)
                                        .foregroundStyle(phase.color)
                                }
                                Spacer()
                                if selectedPhase == phase {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(phase.color)
                                        .font(.title3)
                                }
                            }
                            .padding(14)
                            .background(selectedPhase == phase
                                ? phase.color.opacity(0.08) : Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedPhase == phase
                                    ? phase.color : Color.clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.2), value: selectedPhase)
                    }
                }

                TextField("Any notes? (optional)", text: $notes)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button {
                    if let phase = selectedPhase {
                        store.logToday(phase: phase, notes: notes)
                        dismiss()
                    }
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPhase != nil
                            ? Color(hex: "#D4537E") : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedPhase == nil)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .navigationTitle("Log phase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: — ViewModel

@MainActor
final class CycleViewModel: ObservableObject {
    @Published var insight:   String = ""
    @Published var isLoading: Bool   = false

    private let claude = ClaudeService()

    func fetchInsight(store: CycleStore) async {
        guard !store.recentEntries.isEmpty else { return }
        isLoading = true

        let recent = store.recentEntries.suffix(14).map {
            "\(shortDate($0.date)): \($0.phase.rawValue)\($0.notes.isEmpty ? "" : " (\($0.notes))")"
        }.joined(separator: ", ")

        let current = store.currentPhase?.rawValue ?? "not logged today"

        let prompt = "Recent cycle log (14 days): \(recent). Current phase: \(current)."
        let system = """
        You are Glow. The user has been tracking their cycle phases.
        Give 1-2 sentences connecting their cycle data to how they might be feeling.
        Be warm, specific, and non-clinical. 
        Acknowledge the connection between hormones and mood without being dismissive.
        Never give medical advice. Never say "consult a doctor".
        Example: "You're heading into your luteal phase — if you start feeling more emotional or tired this week, that's your body doing its thing, not something wrong with you."
        """

        insight = (try? await claude.quick(prompt: prompt, system: system))
            ?? "Your cycle and your mood are more connected than most people realise. Keep logging to see your own patterns emerge."
        isLoading = false
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}
