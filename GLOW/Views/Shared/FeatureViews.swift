import SwiftUI

// ─────────────────────────────────────────────
// BREATHE VIEW
// ─────────────────────────────────────────────

struct BreathePattern: Identifiable {
    let id:          String
    let name:        String
    let description: String
    let phases:      [BreathePhase]
    let color:       Color
}

struct BreathePhase {
    let label:    String   // "Inhale", "Hold", "Exhale"
    let seconds:  Int
}

struct BreatheView: View {

    private static let patterns: [BreathePattern] = [
        BreathePattern(
            id: "box",
            name: "Box",
            description: "Calm your nervous system",
            phases: [
                BreathePhase(label: "Inhale", seconds: 4),
                BreathePhase(label: "Hold",   seconds: 4),
                BreathePhase(label: "Exhale", seconds: 4),
                BreathePhase(label: "Hold",   seconds: 4),
            ],
            color: Color(hex: "#1D9E75")
        ),
        BreathePattern(
            id: "478",
            name: "4-7-8",
            description: "Fall asleep faster",
            phases: [
                BreathePhase(label: "Inhale", seconds: 4),
                BreathePhase(label: "Hold",   seconds: 7),
                BreathePhase(label: "Exhale", seconds: 8),
            ],
            color: Color(hex: "#7F77DD")
        ),
        BreathePattern(
            id: "coherence",
            name: "Coherence",
            description: "Ease anxiety quickly",
            phases: [
                BreathePhase(label: "Inhale", seconds: 5),
                BreathePhase(label: "Exhale", seconds: 5),
            ],
            color: Color(hex: "#378ADD")
        ),
    ]

    @State private var selectedPattern: BreathePattern = BreatheView.patterns[0]
    @State private var isActive     = false
    @State private var phaseIndex   = 0
    @State private var countdown    = 0
    @State private var cycleCount   = 0
    @State private var orbScale: CGFloat = 0.65
    @State private var timer: Timer? = nil
    @State private var showDone     = false

    private let targetCycles = 3

    var currentPhase: BreathePhase {
        selectedPattern.phases[phaseIndex % selectedPattern.phases.count]
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if !isActive {
                    patternPicker
                    Spacer()
                    orbArea
                    Spacer()
                    startButton
                        .padding(.bottom, 48)
                } else {
                    Spacer()
                    orbArea
                    Spacer()
                    phaseLabel
                    Spacer()
                    cycleCounter
                    stopButton
                        .padding(.bottom, 48)
                }
            }
            .padding(.horizontal, 24)

            if showDone {
                doneOverlay
            }
        }
        .navigationTitle("Just Breathe")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopSession() }
    }

    // MARK: — Pattern picker

    private var patternPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick a pattern")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.top, 24)

            VStack(spacing: 10) {
                ForEach(BreatheView.patterns) { pattern in
                    patternRow(pattern)
                }
            }
        }
    }

    private func patternRow(_ pattern: BreathePattern) -> some View {
        let isSelected = selectedPattern.id == pattern.id
        let bgColor: Color = isSelected ? pattern.color.opacity(0.08) : Color(UIColor.systemBackground)
        let strokeColor: Color = isSelected ? pattern.color.opacity(0.4) : Color(UIColor.separator)
        let strokeWidth: CGFloat = isSelected ? 1.5 : 0.5

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedPattern = pattern
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(pattern.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(pattern.color)
                        .frame(width: 16, height: 16)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(phasesSummary(pattern))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pattern.description)
                        .font(.caption)
                        .foregroundStyle(pattern.color)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(pattern.color)
                        .font(.title3)
                }
            }
            .padding(14)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
        }
        .buttonStyle(.plain)
    }

    private func phasesSummary(_ p: BreathePattern) -> String {
        p.phases.map { "\($0.seconds)" }.joined(separator: " – ") + " sec"
    }

    // MARK: — Orb

    private var orbArea: some View {
        ZStack {
            Circle()
                .fill(selectedPattern.color.opacity(0.12))
                .frame(width: 220, height: 220)
                .scaleEffect(orbScale * 1.25)
            Circle()
                .fill(selectedPattern.color.opacity(0.20))
                .frame(width: 220, height: 220)
                .scaleEffect(orbScale * 1.1)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [selectedPattern.color.opacity(0.9), selectedPattern.color],
                        center: .center,
                        startRadius: 20,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(orbScale)
                .shadow(color: selectedPattern.color.opacity(0.4), radius: 24, x: 0, y: 8)

            if isActive {
                VStack(spacing: 4) {
                    Text("\(countdown)")
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                    Text(currentPhase.label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            } else {
                Image(systemName: "wind")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 240)
    }

    // MARK: — Phase label (active)

    private var phaseLabel: some View {
        VStack(spacing: 6) {
            Text(phaseInstruction)
                .font(.title2.weight(.semibold))
                .foregroundStyle(selectedPattern.color)
            Text(phaseHint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var phaseInstruction: String {
        switch currentPhase.label {
        case "Inhale": return "Breathe in slowly"
        case "Exhale": return "Let it all out"
        case "Hold":   return "Hold gently"
        default:       return currentPhase.label
        }
    }

    private var phaseHint: String {
        switch currentPhase.label {
        case "Inhale": return "Through your nose, fill your lungs"
        case "Exhale": return "Slow and steady through your mouth"
        case "Hold":   return "Stay still — you're doing great"
        default:       return ""
        }
    }

    // MARK: — Cycle counter

    private var cycleCounter: some View {
        HStack(spacing: 8) {
            ForEach(0..<targetCycles, id: \.self) { i in
                Circle()
                    .fill(i < cycleCount ? selectedPattern.color : selectedPattern.color.opacity(0.2))
                    .frame(width: 10, height: 10)
                    .animation(.spring(response: 0.3), value: cycleCount)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: — Buttons

    private var startButton: some View {
        Button { startSession() } label: {
            Text("Start breathing")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedPattern.color)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var stopButton: some View {
        Button { stopSession() } label: {
            Text("Stop")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: — Done overlay

    private var doneOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🌿")
                    .font(.system(size: 56))
                Text("Well done")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(targetCycles) cycles complete.\nYour nervous system thanks you.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                Button {
                    withAnimation { showDone = false }
                    isActive = false
                    cycleCount = 0
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(selectedPattern.color)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
        }
        .transition(.opacity)
    }

    // MARK: — Session logic

    private func startSession() {
        phaseIndex = 0
        cycleCount = 0
        countdown  = currentPhase.seconds
        isActive   = true
        animateOrb(for: selectedPattern.phases[0])
        scheduleTimer()
    }

    private func stopSession() {
        timer?.invalidate()
        timer = nil
        isActive = false
        withAnimation(.easeInOut(duration: 0.6)) {
            orbScale = 0.65
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            tick()
        }
    }

    private func tick() {
        if countdown > 1 {
            countdown -= 1
        } else {
            let nextIndex = phaseIndex + 1
            let phases    = selectedPattern.phases

            if nextIndex >= phases.count {
                cycleCount += 1
                if cycleCount >= targetCycles {
                    timer?.invalidate()
                    timer = nil
                    withAnimation { showDone = true }
                    return
                }
                phaseIndex = 0
            } else {
                phaseIndex = nextIndex
            }

            countdown = selectedPattern.phases[phaseIndex].seconds
            animateOrb(for: selectedPattern.phases[phaseIndex])
        }
    }

    private func animateOrb(for phase: BreathePhase) {
        let target: CGFloat
        let duration = Double(phase.seconds)
        switch phase.label {
        case "Inhale": target = 1.0
        case "Exhale": target = 0.55
        default:       target = orbScale
        }
        withAnimation(.easeInOut(duration: duration)) {
            orbScale = target
        }
    }
}

// ─────────────────────────────────────────────
// MOVE VIEW
// ─────────────────────────────────────────────
struct MoveView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Yoga & movement").font(.title2.weight(.medium)).padding(.top)
            Text("Coming soon").foregroundStyle(.secondary)
            Spacer()
        }
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
