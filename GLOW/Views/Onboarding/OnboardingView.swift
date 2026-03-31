import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var appState: AppState
    @StateObject private var locationService = LocationService()
    @State private var step    = 0
    @State private var name    = ""
    @State private var age     = ""

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            glowMark
            stepContent
            Spacer()
            nextButton
        }
        .padding(32)
        .animation(.easeInOut, value: step)
    }

    // MARK: — Logo

    private var glowMark: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.min.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: "#EF9F27"))
            Text("Glow")
                .font(.largeTitle.weight(.medium))
        }
    }

    // MARK: — Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            VStack(spacing: 16) {
                Text("What's your name?")
                    .font(.title2.weight(.medium))
                TextField("Your name", text: $name)
                    .textContentType(.givenName)
                    .submitLabel(.continue)
                    .onSubmit { if canAdvance { advance() } }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Continue") { advance() }
                                .disabled(!canAdvance)
                                .fontWeight(.semibold)
                        }
                    }
            }
        case 1:
            VStack(spacing: 16) {
                Text("How old are you?")
                    .font(.title2.weight(.medium))
                TextField("Your age", text: $age)
                    .keyboardType(.numberPad)
                    .submitLabel(.continue)
                    .onSubmit { if canAdvance { advance() } }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Continue") { advance() }
                                .disabled(!canAdvance)
                                .fontWeight(.semibold)
                        }
                    }
            }
        default:
            VStack(spacing: 12) {
                Text("One last thing")
                    .font(.title2.weight(.medium))
                Text("Glow finds real mental health resources near you. To do that, it needs your location — only used to find local help, never shared.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: — Next button

    private var nextButton: some View {
        Button(action: advance) {
            Text(step < 2 ? "Continue" : "Allow location & start")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canAdvance ? Color(hex: "#EF9F27") : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!canAdvance)
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return name.count >= 2
        case 1: return Int(age) != nil
        default: return true
        }
    }

    private func advance() {
        if step == 0 {
            appState.userName = name
            step = 1
        } else if step == 1 {
            appState.userAge = Int(age) ?? 0
            step = 2
        } else {
            locationService.requestPermission()
            appState.hasCompletedOnboarding = true
        }
    }
}
