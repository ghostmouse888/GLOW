import SwiftUI
import Charts
import Combine

// MARK: — Sleep Entry Model

struct SleepEntry: Identifiable, Codable {
    let id:        UUID
    let date:      Date
    let bedtime:   Date
    let wakeTime:  Date

    init(bedtime: Date, wakeTime: Date) {
        self.id       = UUID()
        self.date     = Calendar.current.startOfDay(for: wakeTime)
        self.bedtime  = bedtime
        self.wakeTime = wakeTime
    }

    var duration: Double {
        max(0, wakeTime.timeIntervalSince(bedtime) / 3600)
    }

    var durationText: String {
        let h = Int(duration)
        let m = Int((duration - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    var score: Int {
        switch duration {
        case 9...:    return 100
        case 8..<9:   return 95
        case 7..<8:   return 85
        case 6..<7:   return 70
        case 5..<6:   return 50
        case 4..<5:   return 30
        default:      return 10
        }
    }

    var scoreColor: Color {
        switch score {
        case 85...: return Color(hex: "#1D9E75")
        case 65..<85: return Color(hex: "#EF9F27")
        default:    return Color(hex: "#E24B4A")
        }
    }
}

// MARK: — Sleep Store

final class SleepStore: ObservableObject {
    @Published var entries: [SleepEntry] = []

    init() { load() }

    func save(_ entry: SleepEntry) {
        // Replace existing entry for same day
        entries.removeAll {
            Calendar.current.isDate($0.date, inSameDayAs: entry.date)
        }
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        persist()
    }

    func entry(for date: Date) -> SleepEntry? {
        entries.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    // Last 7 days including today
    var lastSevenDays: [(date: Date, entry: SleepEntry?)] {
        (0..<7).reversed().map { offset in
            let date = Calendar.current.date(
                byAdding: .day, value: -offset, to: Date()
            )!
            return (date, entry(for: date))
        }
    }

    var weeklyAverage: Double {
        let valid = lastSevenDays.compactMap(\.entry?.duration)
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var weeklyScore: Int {
        let valid = lastSevenDays.compactMap(\.entry?.score)
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / valid.count
    }

    var longestStreak: Int {
        var streak = 0, best = 0
        for day in lastSevenDays {
            if day.entry != nil { streak += 1; best = max(best, streak) }
            else { streak = 0 }
        }
        return best
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "glow_sleep_entries")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "glow_sleep_entries"),
              let saved = try? JSONDecoder().decode([SleepEntry].self, from: data)
        else { return }
        entries = saved
    }
}

// MARK: — Main View

struct SleepTrackerView: View {

    @StateObject private var store  = SleepStore()
    @StateObject private var vm     = SleepTrackerViewModel()
    @State private var showLogger   = false
    @State private var selectedEntry: SleepEntry? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                scoreCard
                weekChart
                statsRow
                claudeInsightCard
                logButton
                if !store.entries.isEmpty { historyList }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Sleep tracker")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task { await vm.fetchInsight(store: store) }
        }
        .sheet(isPresented: $showLogger, onDismiss: {
            Task { await vm.fetchInsight(store: store) }
        }) {
            SleepLoggerSheet(store: store)
        }
    }

    // MARK: — Score card

    private var scoreCard: some View {
        HStack(spacing: 0) {
            // Score ring
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemBackground), lineWidth: 10)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: CGFloat(store.weeklyScore) / 100)
                    .stroke(
                        scoreColor(store.weeklyScore),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.spring(response: 0.8), value: store.weeklyScore)

                VStack(spacing: 2) {
                    Text("\(store.weeklyScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(store.weeklyScore))
                        .contentTransition(.numericText())
                    Text("score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 20)

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Weekly average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.weeklyAverage > 0
                         ? String(format: "%.1f hrs", store.weeklyAverage)
                         : "No data")
                        .font(.title2.weight(.semibold))
                }

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(hex: "#EF9F27"))
                        .font(.caption)
                    Text("\(store.longestStreak) day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Score label
                Text(scoreLabel(store.weeklyScore))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(scoreColor(store.weeklyScore))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(scoreColor(store.weeklyScore).opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: — Weekly bar chart

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This week")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Ideal: 8-9 hrs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Custom bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(store.lastSevenDays, id: \.date) { day in
                    VStack(spacing: 4) {
                        // Duration label
                        if let entry = day.entry {
                            Text(entry.durationText)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(entry.scoreColor)
                        } else {
                            Text("—")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }

                        // Bar
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(barColor(for: day.entry))
                                    .frame(
                                        height: barHeight(
                                            for: day.entry?.duration ?? 0,
                                            maxH: geo.size.height
                                        )
                                    )
                            }
                        }
                        .frame(height: 120)

                        // Day label
                        Text(dayLabel(day.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(
                                Calendar.current.isDateInToday(day.date)
                                    ? Color(hex: "#EF9F27") : .secondary
                            )

                        // Today dot
                        Circle()
                            .fill(Calendar.current.isDateInToday(day.date)
                                  ? Color(hex: "#EF9F27") : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(.top, 4)

            // Legend
            HStack(spacing: 16) {
                legendDot(color: Color(hex: "#1D9E75"), label: "Good (7h+)")
                legendDot(color: Color(hex: "#EF9F27"), label: "Okay (5-7h)")
                legendDot(color: Color(hex: "#E24B4A"), label: "Low (<5h)")
                legendDot(color: Color(.tertiarySystemBackground), label: "No data")
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func barHeight(for duration: Double, maxH: CGFloat) -> CGFloat {
        let maxDuration = 10.0
        let minH: CGFloat = 4
        guard duration > 0 else { return minH }
        return max(minH, CGFloat(min(duration, maxDuration) / maxDuration) * maxH)
    }

    private func barColor(for entry: SleepEntry?) -> Color {
        guard let entry else { return Color(.tertiarySystemBackground) }
        return entry.scoreColor.opacity(0.85)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(1))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: — Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(
                value: store.entries.isEmpty ? "—" : String(format: "%.1fh", store.weeklyAverage),
                label: "Avg sleep",
                icon: "moon.fill",
                color: Color(hex: "#7F77DD")
            )
            StatTile(
                value: bestNight,
                label: "Best night",
                icon: "star.fill",
                color: Color(hex: "#EF9F27")
            )
            StatTile(
                value: "\(store.longestStreak)/7",
                label: "Days logged",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#1D9E75")
            )
        }
    }

    private var bestNight: String {
        guard let best = store.lastSevenDays.compactMap(\.entry).max(by: { $0.duration < $1.duration })
        else { return "—" }
        return best.durationText
    }

    // MARK: — Claude insight

    private var claudeInsightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sun.min.fill")
                    .foregroundStyle(Color(hex: "#EF9F27"))
                    .font(.subheadline)
                Text("Glow's take")
                    .font(.subheadline.weight(.semibold))
            }

            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color(hex: "#EF9F27"))
                        .scaleEffect(0.8)
                    Text("Analysing your sleep...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if !vm.insight.isEmpty {
                Text(vm.insight)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            } else {
                Text("Log a few nights to get your personal sleep insight.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: — Log button

    private var logButton: some View {
        Button { showLogger = true } label: {
            HStack(spacing: 10) {
                Image(systemName: store.entry(for: Date()) != nil
                      ? "pencil" : "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text(store.entry(for: Date()) != nil
                     ? "Edit today's sleep" : "Log last night's sleep")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "#EF9F27"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: — History list

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ForEach(store.entries.reversed().prefix(7)) { entry in
                SleepHistoryRow(entry: entry)
            }
        }
    }

    // MARK: — Helpers

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 85...: return Color(hex: "#1D9E75")
        case 65..<85: return Color(hex: "#EF9F27")
        default:    return Color(hex: "#E24B4A")
        }
    }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 90...: return "Excellent"
        case 75..<90: return "Good"
        case 55..<75: return "Okay"
        case 35..<55: return "Poor"
        default:    return score == 0 ? "No data" : "Very low"
        }
    }
}

// MARK: — Sleep Logger Sheet

struct SleepLoggerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: SleepStore

    @State private var bedtime:  Date = defaultBedtime()
    @State private var wakeTime: Date = defaultWakeTime()

    var duration: Double {
        max(0, wakeTime.timeIntervalSince(adjustedBedtime) / 3600)
    }

    // If bedtime is after noon it's probably last night
    var adjustedBedtime: Date {
        let cal = Calendar.current
        let bedH = cal.component(.hour, from: bedtime)
        if bedH < 12 {
            // Bedtime is early morning — same day as wake
            return bedtime
        } else {
            // Bedtime is evening — previous day relative to wake
            let wakeDay = cal.startOfDay(for: wakeTime)
            let prev    = cal.date(byAdding: .day, value: -1, to: wakeDay)!
            var comps   = cal.dateComponents([.hour, .minute], from: bedtime)
            comps.year  = cal.component(.year,  from: prev)
            comps.month = cal.component(.month, from: prev)
            comps.day   = cal.component(.day,   from: prev)
            return cal.date(from: comps) ?? bedtime
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Duration display
                VStack(spacing: 6) {
                    Text(duration > 0
                         ? String(format: "%.1f hours", duration)
                         : "Adjust times")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(durationColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: duration)

                    Text(durationFeedback)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGroupedBackground))

                Form {
                    Section("Last night") {
                        DatePicker(
                            "Went to sleep",
                            selection: $bedtime,
                            displayedComponents: .hourAndMinute
                        )
                        .tint(Color(hex: "#EF9F27"))

                        DatePicker(
                            "Woke up",
                            selection: $wakeTime,
                            displayedComponents: .hourAndMinute
                        )
                        .tint(Color(hex: "#EF9F27"))
                    }

                    Section {
                        HStack {
                            Text("Sleep score")
                            Spacer()
                            Text("\(scoreForDuration(duration))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(durationColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(durationColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    } footer: {
                        Text("Teens need 8-10 hours. Adults 7-9 hours.")
                            .font(.caption)
                    }
                }

                // Save button
                Button {
                    let entry = SleepEntry(bedtime: adjustedBedtime, wakeTime: wakeTime)
                    store.save(entry)
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(duration > 0
                                    ? Color(hex: "#EF9F27") : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(duration <= 0)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Log sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var durationColor: Color {
        switch duration {
        case 8...: return Color(hex: "#1D9E75")
        case 6..<8: return Color(hex: "#EF9F27")
        default:   return Color(hex: "#E24B4A")
        }
    }

    private var durationFeedback: String {
        switch duration {
        case 9...:    return "Perfect — well rested 🌟"
        case 8..<9:   return "Great night's sleep"
        case 7..<8:   return "Good, could be a bit more"
        case 6..<7:   return "A bit short for a teen"
        case 5..<6:   return "Not enough — you'll feel it"
        case 0..<5:   return "Very short — rest up tonight"
        default:      return "Adjust your times"
        }
    }

    private func scoreForDuration(_ d: Double) -> Int {
        switch d {
        case 9...:   return 100
        case 8..<9:  return 95
        case 7..<8:  return 85
        case 6..<7:  return 70
        case 5..<6:  return 50
        case 4..<5:  return 30
        default:     return 10
        }
    }

    private static func defaultBedtime() -> Date {
        Calendar.current.date(
            bySettingHour: 23, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }

    private static func defaultWakeTime() -> Date {
        Calendar.current.date(
            bySettingHour: 7, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }
}

// MARK: — History Row

struct SleepHistoryRow: View {
    let entry: SleepEntry

    var body: some View {
        HStack(spacing: 14) {
            // Date column
            VStack(spacing: 2) {
                Text(entry.dayLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(shortDate(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 36)

            // Bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(entry.scoreColor.opacity(0.8))
                        .frame(
                            width: min(
                                CGFloat(entry.duration / 10) * geo.size.width,
                                geo.size.width
                            )
                        )
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 20)

            // Duration + score
            HStack(spacing: 6) {
                Text(entry.durationText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("\(entry.score)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.scoreColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(entry.scoreColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .frame(width: 90, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

// MARK: — Stat Tile

struct StatTile: View {
    let value: String
    let label: String
    let icon:  String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 18))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: — ViewModel (Claude insight)

@MainActor
final class SleepTrackerViewModel: ObservableObject {
    @Published var insight:   String = ""
    @Published var isLoading: Bool   = false

    private let claude = ClaudeService()

    func fetchInsight(store: SleepStore) async {
        guard !store.entries.isEmpty else { return }

        isLoading = true

        let avg      = store.weeklyAverage
        let score    = store.weeklyScore
        let logged   = store.lastSevenDays.filter { $0.entry != nil }.count
        let durations = store.lastSevenDays
            .compactMap { $0.entry?.duration }
            .map { String(format: "%.1f", $0) }
            .joined(separator: ", ")

        let prompt = """
        Sleep data for the past 7 days:
        Durations (hours): \(durations)
        Average: \(String(format: "%.1f", avg)) hours
        Weekly score: \(score)/100
        Days logged: \(logged)/7
        """

        let system = """
        You are Glow's sleep analyst. Give exactly ONE insight in 2 sentences max.
        Be direct and data-driven — no fluff, no "great job", no cheerfulness.
        Mention the actual number. Give one specific, actionable observation.
        Examples:
        "You averaged 5.5 hours this week — that's why you might feel sluggish. Try moving bedtime 30 minutes earlier for 3 nights."
        "6 out of 7 nights logged — solid consistency. Your Thursday dip to 5h likely affected your Friday."
        Never use bullet points. Never list multiple things. One sharp observation.
        """

        insight = (try? await claude.quick(prompt: prompt, system: system))
            ?? "Log a full week to get your personal sleep insight."
        isLoading = false
    }
}

