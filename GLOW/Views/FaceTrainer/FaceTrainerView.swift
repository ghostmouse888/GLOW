import SwiftUI
import AVFoundation
import Combine

// MARK: — Entry point

struct FaceTrainerView: View {
    @StateObject private var vm = FaceTrainerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch vm.screen {
            case .picker:      ZonePickerScreen(vm: vm)
            case .calibrating: CalibratingScreen()
            case .exercise:    ExerciseScreen(vm: vm)
            case .rest:        RestScreen(vm: vm)
            case .complete:    CompleteScreen(vm: vm, onDismiss: { dismiss() })
            }
        }
        .navigationBarBackButtonHidden(vm.screen != .picker)
        .toolbar {
            if vm.screen == .exercise || vm.screen == .rest {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") { vm.reset() }
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: — Screen 1: Zone Picker

private struct ZonePickerScreen: View {
    @ObservedObject var vm: FaceTrainerViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: "#1D9E75"))
                    Text("Face trainer")
                        .font(.title.weight(.semibold))
                    Text("Based on Fumiko Inudo's Face Training method")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Zone grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a zone")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(FaceZone.allCases) { zone in
                            ZoneCard(zone: zone) {
                                vm.startSession(mode: .zone(zone))
                            }
                        }
                    }
                }

                // Full session button
                Button {
                    vm.startSession(mode: .full)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Full session")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("All 15 exercises · ~15 min")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                    }
                    .padding(18)
                    .background(Color(hex: "#1D9E75"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Permission denied warning
                if vm.detector.permissionDenied {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.orange)
                        Text("Camera access needed. Go to Settings → Glow → Camera to enable.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Face trainer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ZoneCard: View {
    let zone: FaceZone
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(zone.bgColor)
                        .frame(width: 48, height: 48)
                    Text(zone.emoji)
                        .font(.system(size: 24))
                }
                Text(zone.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(zone.exerciseCount) exercises · \(zone.duration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(zone.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: — Screen 1.5: Calibrating

private struct CalibratingScreen: View {
    @State private var dots = 1
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
                Text("Reading your face" + String(repeating: ".", count: dots))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Hold still for a moment")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .onReceive(timer) { _ in
            dots = dots % 3 + 1
        }
    }
}

// MARK: — Screen 2: Exercise (camera + UI overlay)

private struct ExerciseScreen: View {
    @ObservedObject var vm: FaceTrainerViewModel

    var body: some View {
        guard let ex = vm.currentExercise else { return AnyView(EmptyView()) }
        return AnyView(
            ZStack {
                // Layer 1: Live camera feed
                CameraPreviewView(session: vm.detector.session)
                    .ignoresSafeArea()

                // Layer 2: Dark overlay
                Color.black.opacity(0.38).ignoresSafeArea()

                // Layer 3: Face guide ellipse
                Ellipse()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 220, height: 290)

                // Layer 4: UI
                VStack(spacing: 0) {
                    topBar(ex: ex)
                    Spacer()
                    centreCard(ex: ex)
                    Spacer()
                    bottomPanel(ex: ex)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        )
    }

    @ViewBuilder
    private func topBar(ex: FaceExercise) -> some View {
        HStack {
            // Progress pills
            HStack(spacing: 4) {
                ForEach(0..<vm.totalExercises, id: \.self) { i in
                    Capsule()
                        .fill(i < vm.exerciseIndex ? Color.white :
                              i == vm.exerciseIndex ? ex.zone.color : Color.white.opacity(0.3))
                        .frame(width: i == vm.exerciseIndex ? 20 : 8, height: 6)
                        .animation(.spring(response: 0.3), value: vm.exerciseIndex)
                }
            }
            Spacer()
            // Zone badge
            HStack(spacing: 4) {
                Text(ex.zone.emoji)
                    .font(.system(size: 14))
                Text(ex.zone.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func centreCard(ex: FaceExercise) -> some View {
        VStack(spacing: 14) {
            // Emoji with detection ring
            ZStack {
                // Detection ring
                Circle()
                    .stroke(
                        vm.isDetected ? ex.zone.color : Color.white.opacity(0.3),
                        lineWidth: vm.isDetected ? 3 : 1.5
                    )
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 0.2), value: vm.isDetected)

                // Progress ring
                if vm.holdProgress > 0 {
                    Circle()
                        .trim(from: 0, to: vm.holdProgress)
                        .stroke(ex.zone.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: vm.holdProgress)
                }

                Text(ex.emoji)
                    .font(.system(size: 58))
                    .scaleEffect(vm.isDetected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: vm.isDetected)
            }

            // Exercise name
            Text(ex.name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Instruction
            Text(ex.instruction)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .lineLimit(3)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func bottomPanel(ex: FaceExercise) -> some View {
        VStack(spacing: 12) {
            // Detection status
            HStack(spacing: 8) {
                Circle()
                    .fill(vm.isDetected ? ex.zone.color : Color.white.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: vm.isDetected)
                Text(vm.isDetected
                     ? (vm.secondsRemaining > 0 ? "Hold it! \(vm.secondsRemaining)s remaining" : "Great!")
                     : "Get into position...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(vm.isDetected ? ex.zone.color : .white.opacity(0.7))
                    .animation(.easeInOut, value: vm.isDetected)
            }

            // Hold progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(ex.zone.color)
                        .frame(width: geo.size.width * vm.holdProgress)
                        .animation(.linear(duration: 0.1), value: vm.holdProgress)
                }
            }
            .frame(height: 6)

            // Muscle name
            Text("Training: \(ex.muscle)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))

            // Tip
            Text(ex.tip)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
        }
        .padding(18)
        .background(Color.black.opacity(0.6))
        .padding(.horizontal, 0)
    }
}

// MARK: — Screen 3: Rest

private struct RestScreen: View {
    @ObservedObject var vm: FaceTrainerViewModel

    var nextExercise: FaceExercise? {
        let next = vm.exerciseIndex + 1
        guard next < vm.exercises.count else { return nil }
        return vm.exercises[next]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Rest")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)

                // Countdown circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    Text("\(vm.restCountdown)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                if let next = nextExercise {
                    VStack(spacing: 6) {
                        Text("Next up")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        HStack(spacing: 8) {
                            Text(next.emoji)
                                .font(.system(size: 28))
                            Text(next.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        Text(next.muscle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("Last one!")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(40)
        }
    }
}

// MARK: — Screen 4: Complete

private struct CompleteScreen: View {
    @ObservedObject var vm: FaceTrainerViewModel
    let onDismiss: () -> Void

    private var durationText: String {
        let m = Int(vm.sessionDuration) / 60
        let s = Int(vm.sessionDuration) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Success badge
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E1F5EE"))
                        .frame(width: 90, height: 90)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1D9E75"))
                }
                .padding(.top, 32)

                VStack(spacing: 6) {
                    Text("Session complete!")
                        .font(.title.weight(.semibold))
                    Text("Your face just got a real workout 💪")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats row
                HStack(spacing: 12) {
                    StatBadge(value: "\(vm.exercises.count)", label: "Exercises")
                    StatBadge(value: durationText, label: "Time")
                    StatBadge(value: "\(Set(vm.exercises.map(\.zone.rawValue)).count)", label: "Zones")
                }

                // Claude feedback
                if vm.isLoadingFeedback {
                    HStack(spacing: 10) {
                        ProgressView().tint(Color(hex: "#1D9E75"))
                        Text("Glow is thinking...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                } else if !vm.feedbackText.isEmpty {
                    Text(vm.feedbackText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(18)
                        .background(Color(hex: "#E1F5EE"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 4)
                }

                // Exercises done
                VStack(alignment: .leading, spacing: 8) {
                    Text("What you trained")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    ForEach(vm.exercises) { ex in
                        HStack(spacing: 10) {
                            Text(ex.emoji).font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ex.name)
                                    .font(.subheadline.weight(.medium))
                                Text(ex.muscle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ex.zone.color)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Buttons
                VStack(spacing: 10) {
                    Button("Done") { onDismiss() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#1D9E75"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button("Do another session") { vm.reset() }
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#1D9E75"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden()
    }
}

private struct StatBadge: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title2.weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
