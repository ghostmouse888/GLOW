import SwiftUI

struct WinsView: View {
    @EnvironmentObject var appState: AppState
    private let claude = ClaudeService()

    @State private var bigWin    = ""
    @State private var smallWin  = ""
    @State private var grateful  = ""
    @State private var response  = ""
    @State private var isLoading = false
    @State private var submitted = false
    @State private var history: [WinEntry] = []
    @State private var showHistory = false

    private let amber      = Color(hex: "#EF9F27")
    private let amberLight = Color(hex: "#FAEEDA")

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFFBF2"), Color(hex: "#FFF3D6")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                Divider().padding(.top, 12)
                ScrollView {
                    VStack(spacing: 20) {
                        if showHistory {
                            historySection
                        } else if submitted {
                            celebrationSection
                        } else {
                            entrySection
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Wins")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadHistory() }
    }

    // MARK: — Header

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(amber).font(.title3)
                    Text("Today's wins").font(.title2.weight(.medium))
                }
                Text("No win is too small.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if !history.isEmpty {
                Button(showHistory ? "Add wins" : "History") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHistory.toggle()
                        if showHistory { submitted = false }
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(amber)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: — Entry form

    private var entrySection: some View {
        VStack(spacing: 16) {
            WinCard(
                icon: "trophy.fill", iconColor: amber, iconBg: amberLight,
                label: "A big win today",
                placeholder: "Something you achieved, big or small…",
                text: $bigWin
            )
            WinCard(
                icon: "sparkles", iconColor: amber, iconBg: amberLight,
                label: "A small win",
                placeholder: "Even tiny things count…",
                text: $smallWin
            )
            WinCard(
                icon: "heart.fill", iconColor: Color(hex: "#D85A30"), iconBg: Color(hex: "#FAECE7"),
                label: "Something I'm grateful for",
                placeholder: "Big or small, anything goes…",
                text: $grateful
            )

            Button {
                Task { await saveWins() }
            } label: {
                Label("Save my wins", systemImage: "star.fill")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(bigWin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color(.systemGray4) : amber)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(bigWin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
    }

    // MARK: — Celebration

    private var celebrationSection: some View {
        VStack(spacing: 20) {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(amber)
                    Text("Celebrating your wins…")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(40)
                .background(Color(.systemBackground).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                // Star burst
                VStack(spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundStyle(amber)
                                .font(.system(size: 18))
                        }
                    }
                    Text("You crushed it today")
                        .font(.headline).foregroundStyle(amber)
                }
                .padding(.top, 8)

                // Recap card
                VStack(alignment: .leading, spacing: 12) {
                    winRecapRow(icon: "trophy.fill", color: amber, label: "Big win", value: bigWin)
                    Divider()
                    winRecapRow(icon: "sparkles", color: amber, label: "Small win", value: smallWin)
                    if !grateful.isEmpty {
                        Divider()
                        winRecapRow(icon: "heart.fill", color: Color(hex: "#D85A30"), label: "Grateful for", value: grateful)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground).opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Glow response
                if !response.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Glow says", systemImage: "sun.min.fill")
                            .font(.caption.weight(.semibold)).foregroundStyle(amber)
                        Text(response)
                            .font(.body).lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(amberLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    bigWin = ""; smallWin = ""; grateful = ""
                    response = ""; submitted = false
                    showHistory = false
                } label: {
                    Label("Log more wins", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(amber)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(amber.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
    }

    private func winRecapRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
        }
    }

    // MARK: — History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Past wins")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            if history.isEmpty {
                Text("No wins saved yet — log your first one!")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(24)
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(history) { entry in
                    WinHistoryCard(entry: entry, amber: amber, amberLight: amberLight)
                }
            }
        }
    }

    // MARK: — Logic

    private func saveWins() async {
        isLoading = true
        submitted = true
        let prompt = "Big win: \(bigWin)\nSmall win: \(smallWin)\nGrateful for: \(grateful)"
        response = (try? await claude.quick(
            prompt: prompt,
            system: SystemPromptBuilder.wins(userName: appState.userName)
        )) ?? "Those are genuinely great wins — you should be proud of yourself today."
        let entry = WinEntry(bigWin: bigWin, smallWin: smallWin, grateful: grateful, response: response)
        history.insert(entry, at: 0)
        if history.count > 30 { history.removeLast() }
        persistHistory()
        isLoading = false
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "winsHistory")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "winsHistory"),
              let entries = try? JSONDecoder().decode([WinEntry].self, from: data)
        else { return }
        history = entries
    }
}

// MARK: — Supporting views

struct WinCard: View {
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(iconBg).frame(width: 28, height: 28)
                    Image(systemName: icon).foregroundStyle(iconColor).font(.system(size: 12))
                }
                Text(label).font(.subheadline.weight(.medium))
            }
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding(10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color(.separator) : iconColor.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(16)
        .background(Color(.systemBackground).opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct WinHistoryCard: View {
    let entry: WinEntry
    let amber: Color
    let amberLight: Color

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill").foregroundStyle(amber).font(.caption)
                Text(dateLabel).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
            }
            Text(entry.bigWin).font(.subheadline.weight(.medium)).lineLimit(2)
            if !entry.smallWin.isEmpty {
                Text(entry.smallWin).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            if !entry.response.isEmpty {
                Text(entry.response)
                    .font(.caption).foregroundStyle(amber)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(amberLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Color(.systemBackground).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
