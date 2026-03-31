import SwiftUI

struct BodyCheckView: View {
    private let claude = ClaudeService()

    @State private var energy    = 5.0
    @State private var hunger    = 5.0
    @State private var tiredness = 5.0
    @State private var tension: Set<String> = []
    @State private var response  = ""
    @State private var isLoading = false
    @State private var checked   = false

    private let coral      = Color(hex: "#D85A30")
    private let coralLight = Color(hex: "#FAECE7")

    private let bodyParts = ["Head", "Neck", "Shoulders", "Chest", "Stomach", "Back", "Hands", "Legs"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF8F5"), Color(hex: "#FAECE7")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                Divider().padding(.top, 12)
                ScrollView {
                    VStack(spacing: 20) {
                        if checked {
                            resultSection
                        } else {
                            slidersSection
                            tensionSection
                            checkInButton
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Body check")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: — Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .foregroundStyle(coral).font(.title3)
                Text("Body check-in").font(.title2.weight(.medium))
                Spacer()
            }
            Text("How does your body feel right now?")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: — Sliders

    private var slidersSection: some View {
        VStack(spacing: 12) {
            BodySlider(
                label: "Energy", emoji: "⚡️",
                value: $energy,
                lowLabel: "Drained", highLabel: "Buzzing",
                color: Color(hex: "#EF9F27")
            )
            BodySlider(
                label: "Hunger", emoji: "🍎",
                value: $hunger,
                lowLabel: "Not hungry", highLabel: "Starving",
                color: coral
            )
            BodySlider(
                label: "Tiredness", emoji: "😴",
                value: $tiredness,
                lowLabel: "Wide awake", highLabel: "Exhausted",
                color: Color(hex: "#7F77DD")
            )
        }
        .padding(18)
        .background(Color(.systemBackground).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: — Tension picker

    private var tensionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundStyle(coral).font(.subheadline)
                Text("Where do you feel tension?")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if !tension.isEmpty {
                    Text("\(tension.count) selected")
                        .font(.caption).foregroundStyle(coral)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(bodyParts, id: \.self) { part in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if tension.contains(part) { tension.remove(part) }
                            else { tension.insert(part) }
                        }
                    } label: {
                        Text(part)
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(tension.contains(part) ? coralLight : Color(.systemBackground))
                            .foregroundStyle(tension.contains(part) ? coral : Color(.secondaryLabel))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(tension.contains(part) ? coral.opacity(0.4) : Color(.separator), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if tension.isEmpty {
                Text("Tap any area that feels tense or uncomfortable")
                    .font(.caption).foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(18)
        .background(Color(.systemBackground).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: — Check-in button

    private var checkInButton: some View {
        Button {
            Task { await doCheck() }
        } label: {
            Label("Check in", systemImage: "figure.stand")
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding()
                .background(coral)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: — Result

    private var resultSection: some View {
        VStack(spacing: 16) {
            // Snapshot card
            VStack(spacing: 14) {
                Text("Your body snapshot")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    SnapshotPill(label: "Energy",   value: Int(energy),   color: Color(hex: "#EF9F27"), emoji: "⚡️")
                    Divider().frame(height: 36)
                    SnapshotPill(label: "Hunger",   value: Int(hunger),   color: coral,                emoji: "🍎")
                    Divider().frame(height: 36)
                    SnapshotPill(label: "Tiredness", value: Int(tiredness), color: Color(hex: "#7F77DD"), emoji: "😴")
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !tension.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.up.left.fill")
                            .foregroundStyle(coral).font(.caption)
                        Text("Tension: \(tension.sorted().joined(separator: ", "))")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground).opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Glow suggestion
            if isLoading {
                VStack(spacing: 10) {
                    ProgressView().tint(coral)
                    Text("Reading your body signals…")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(36)
                .background(Color(.systemBackground).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else if !response.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("One thing to try", systemImage: "lightbulb.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(coral)
                    Text(response)
                        .font(.body).lineSpacing(5)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(coralLight)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button {
                tension = []; response = ""; checked = false
                energy = 5; hunger = 5; tiredness = 5
            } label: {
                Label("Check in again", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(coral)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(coral.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: — Logic

    private func doCheck() async {
        checked  = true
        isLoading = true
        let tensionText = tension.isEmpty ? "none" : tension.sorted().joined(separator: ", ")
        let prompt = "Energy: \(Int(energy))/10, Hunger: \(Int(hunger))/10, Tiredness: \(Int(tiredness))/10, Tension in: \(tensionText)"
        response = (try? await claude.quick(
            prompt: prompt,
            system: SystemPromptBuilder.bodyCheck()
        )) ?? "Your body is giving you signals — try a quick stretch, have some water, and take three slow breaths."
        isLoading = false
    }
}

// MARK: — Supporting views

struct BodySlider: View {
    let label: String
    let emoji: String
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(emoji) \(label)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(value))")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 24, alignment: .trailing)
                Text("/ 10")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 1...10, step: 1).tint(color)
            HStack {
                Text(lowLabel).font(.caption2).foregroundStyle(Color(.tertiaryLabel))
                Spacer()
                Text(highLabel).font(.caption2).foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 4)
    }
}

struct SnapshotPill: View {
    let label: String
    let value: Int
    let color: Color
    let emoji: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title3)
            Text("\(value)").font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}
