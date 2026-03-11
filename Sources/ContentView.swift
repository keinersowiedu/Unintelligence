import SwiftUI

struct ContentView: View {
    @StateObject private var manager = AIRemoverManager()
    @State private var showRecoveryInfo = false
    @State private var showRebootConfirm = false
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.06, blue: 0.18),
                    Color(red: 0.04, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack { Spacer() }.frame(height: 28)

                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        statusCard

                        if !manager.modelFiles.isEmpty {
                            filesCard
                        }

                        actionButtons

                        if !manager.logMessages.isEmpty {
                            logCard
                        }

                        if showRecoveryInfo {
                            recoveryInfoCard
                        }
                    }
                    .padding(24)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.red.opacity(0.3), Color.clear],
                        center: .center, startRadius: 0, endRadius: 50
                    ))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animatePulse ? 1.2 : 1.0)

                Image(systemName: "brain")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            }

            Text("Apple Intelligence Remover")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Reclaim your storage space")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(manager.isAppleIntelligenceEnabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text("Apple Intelligence")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text(manager.isAppleIntelligenceEnabled ? "Enabled" : "Disabled")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(manager.isAppleIntelligenceEnabled ? .green : .gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(manager.isAppleIntelligenceEnabled
                            ? Color.green.opacity(0.15)
                            : Color.gray.opacity(0.15))
                    )
            }

            if case .found(let totalSize) = manager.status, totalSize > 0 {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))

                    Text("Storage used by AI models:")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text(manager.formatBytes(totalSize))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }

            if case .scanning = manager.status {
                ProgressView(value: manager.progress)
                    .tint(.orange)
                    .scaleEffect(y: 1.5)
            }

            if case .removing = manager.status {
                ProgressView(value: manager.progress)
                    .tint(.red)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var filesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Found Files")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(manager.modelFiles.count) items")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }

            ForEach(Array(manager.modelFiles.enumerated()), id: \.element.id) { index, file in
                HStack(spacing: 10) {
                    Button {
                        manager.modelFiles[index].isSelected.toggle()
                    } label: {
                        Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(file.isSelected ? .orange : .gray)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "folder.fill")
                        .foregroundColor(.orange.opacity(0.7))
                        .font(.system(size: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        Text(file.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(manager.formatBytes(file.size))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.red)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(file.isSelected ? 0.05 : 0.02)))
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                manager.scan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text(manager.status == .idle ? "Scan for AI Models" : "Re-Scan")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)],
                                         startPoint: .leading, endPoint: .trailing)))
            }
            .buttonStyle(.plain)
            .disabled(manager.status == .scanning || manager.status == .removing)

            HStack(spacing: 10) {
                Button {
                    manager.disableAppleIntelligence()
                } label: {
                    actionLabel("power", "Disable AI", .orange.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(!manager.isAppleIntelligenceEnabled)

                Button {
                    manager.removeSelected()
                } label: {
                    actionLabel("trash", "Remove Files", .red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .disabled(manager.modelFiles.filter { $0.isSelected }.isEmpty)
            }

            HStack(spacing: 10) {
                Button { manager.saveRecoveryScript() } label: {
                    secondaryLabel("doc.text", "Save Recovery Script")
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.3)) { showRecoveryInfo.toggle() }
                } label: {
                    secondaryLabel("questionmark.circle", "Recovery Guide")
                }
                .buttonStyle(.plain)
            }

            Button { showRebootConfirm = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reboot to Recovery Mode")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)],
                                         startPoint: .leading, endPoint: .trailing)))
            }
            .buttonStyle(.plain)
            .alert("Reboot to Recovery Mode?", isPresented: $showRebootConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reboot", role: .destructive) { manager.rebootToRecovery() }
            } message: {
                Text("Your Mac will restart into Recovery Mode. Save your work first.")
            }
        }
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Log")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button { manager.logMessages = [] } label: {
                    Text("Clear")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(manager.logMessages.enumerated()), id: \.offset) { _, msg in
                        Text(msg)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.3))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private var recoveryInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Recovery Mode Guide")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                stepRow(1, "Go to System Settings → Apple Intelligence & Siri → Turn OFF")
                stepRow(2, "Shut down your Mac completely")
                stepRow(3, "Hold Power button until 'Loading options' appears")
                stepRow(4, "Select Options → Continue to Recovery Mode")
                stepRow(5, "Open Terminal from Utilities menu")
                stepRow(6, "Mount the Data volume:")
                codeBlock("diskutil mount \"Macintosh HD - Data\"")
                stepRow(7, "Remove the AI model directories:")
                codeBlock("""
                rm -rf /Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels
                rm -rf /Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual
                """)
                stepRow(8, "Restart your Mac")
            }

            Text("Or use 'Save Recovery Script' to export these commands as a file.")
                .font(.system(size: 11))
                .foregroundColor(.yellow.opacity(0.8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.yellow.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.yellow.opacity(0.15), lineWidth: 1))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // Reusable pieces

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func actionLabel(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(RoundedRectangle(cornerRadius: 10).fill(color))
    }

    private func secondaryLabel(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    private func stepRow(_ num: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(num).")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
                .frame(width: 20, alignment: .trailing)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func codeBlock(_ code: String) -> some View {
        Text(code)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.green.opacity(0.9))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.5)))
            .textSelection(.enabled)
            .padding(.leading, 28)
    }
}

#Preview {
    ContentView()
        .frame(width: 580, height: 620)
}
