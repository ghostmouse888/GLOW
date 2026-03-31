import SwiftUI

struct ChatView: View {

    @EnvironmentObject var appState: AppState
    @StateObject private var locationService = LocationService()
    @StateObject private var vm = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            messageList
            if let err = vm.errorBanner { errorBanner(err) }
            inputBar
        }
        .background(Color(.systemBackground))
        .task { await vm.startSession(appState: appState, location: locationService) }
    }

    // MARK: — Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Glow")
                    .font(.headline)
                Text("always here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Crisis button — always visible
            Button {
                if let url = URL(string: "tel://988") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("988", systemImage: "phone.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: — Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.messages.filter { !$0.content.hasPrefix("[opener]") }) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if vm.isThinking { TypingIndicator() }
                }
                .padding()
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: — Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("How are you feeling?", text: $vm.inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit { Task { await vm.send(appState: appState) } }

            Button {
                Task { await vm.send(appState: appState) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(vm.inputText.isEmpty ? .gray : Color(hex: "#EF9F27"))
            }
            .disabled(vm.inputText.isEmpty || vm.isThinking)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: — Error banner

    private func errorBanner(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.85))
    }
}

// MARK: — Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(.tertiaryLabel))
                    .frame(width: 8, height: 8)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { phase = 2 }
    }
}

// MARK: — Message Bubble

struct MessageBubble: View {

    let message: Message

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(message.content)
                .font(.body)
                .foregroundStyle(isUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color(hex: "#EF9F27") : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

