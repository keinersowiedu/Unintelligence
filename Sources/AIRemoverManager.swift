import Foundation
import Combine

enum RemovalStatus: Equatable {
    case idle, scanning, removing, disabling, needsRoot
    case found(totalSize: Int64)
    case done(freedSpace: Int64)
    case error(String)

    static func == (lhs: RemovalStatus, rhs: RemovalStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning), (.removing, .removing),
             (.disabling, .disabling), (.needsRoot, .needsRoot):
            return true
        case (.found(let a), .found(let b)): return a == b
        case (.done(let a), .done(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

struct AIModelFile: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let size: Int64
    var isSelected: Bool = true
}

@MainActor
class AIRemoverManager: ObservableObject {
    @Published var status: RemovalStatus = .idle
    @Published var modelFiles: [AIModelFile] = []
    @Published var isAppleIntelligenceEnabled = false
    @Published var progress: Double = 0
    @Published var logMessages: [String] = []

    private let modelPaths: [String] = [
        "/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels",
        "/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual",
        "/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels",
        "/Library/Apple/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual",
        "/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels",
        "/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual",
    ]

    private let cachePaths: [String] = [
        "~/Library/Caches/com.apple.intelligence",
        "~/Library/Caches/com.apple.siri",
        "/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_GenerativeModels",
        "/private/var/db/MobileAsset/AssetsV2/com_apple_MobileAsset_UAF_FM_Visual",
    ]

    init() {
        checkAppleIntelligenceStatus()
    }

    func checkAppleIntelligenceStatus() {
        let out = shell("defaults read com.apple.Siri AppleIntelligenceEnabled 2>/dev/null")
        isAppleIntelligenceEnabled = out.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
    }

    func scan() {
        status = .scanning
        progress = 0
        modelFiles = []
        logMessages = []
        log("Scanning for Apple Intelligence model files...")

        Task {
            var found: [AIModelFile] = []
            let allPaths = modelPaths + cachePaths.map { ($0 as NSString).expandingTildeInPath }
            let total = Double(allPaths.count)

            for (i, path) in allPaths.enumerated() {
                progress = Double(i + 1) / total
                let fm = FileManager.default
                guard fm.fileExists(atPath: path) else { continue }
                let size = dirSize(path)
                guard size > 0 else { continue }
                let name = (path as NSString).lastPathComponent
                found.append(AIModelFile(path: path, name: name, size: size))
                log("Found: \(name) (\(formatBytes(size)))")
            }

            modelFiles = found
            let totalSize = found.reduce(0) { $0 + $1.size }

            if totalSize > 0 {
                status = .found(totalSize: totalSize)
                log("Total: \(formatBytes(totalSize))")
            } else {
                status = .found(totalSize: 0)
                log("No removable files found.")
                log("Models may be on the Data volume — use Recovery Mode to remove them.")
            }
        }
    }

    func disableAppleIntelligence() {
        status = .disabling
        log("Disabling Apple Intelligence...")

        shell("defaults write com.apple.Siri AppleIntelligenceEnabled -bool false")
        shell("defaults write com.apple.Siri LLMEnable -bool false")

        isAppleIntelligenceEnabled = false
        log("Disabled. Also turn it off in System Settings > Apple Intelligence & Siri.")
        status = .idle
    }

    func removeSelected() {
        let selected = modelFiles.filter { $0.isSelected }
        guard !selected.isEmpty else { return }

        status = .removing
        progress = 0
        log("Removing selected files...")

        Task {
            var totalFreed: Int64 = 0
            var needsElevation = false
            let count = Double(selected.count)

            for (i, file) in selected.enumerated() {
                progress = Double(i + 1) / count
                log("  Removing: \(file.name)...")

                do {
                    try FileManager.default.removeItem(atPath: file.path)
                    totalFreed += file.size
                    log("  ✅ Removed (\(formatBytes(file.size)))")
                } catch {
                    log("  Direct removal failed, trying admin...")
                    let result = privilegedShell("rm -rf '\(file.path)'")

                    if result.contains("error") || result.contains("denied") ||
                       FileManager.default.fileExists(atPath: file.path) {
                        needsElevation = true
                        log("  Protected by SIP — needs Recovery Mode")
                    } else {
                        totalFreed += file.size
                        log("  Removed (\(formatBytes(file.size)))")
                    }
                }
            }

            if needsElevation {
                status = .needsRoot
                log("")
                log("Some files are SIP-protected. To fully remove:")
                log("  1. Disable Apple Intelligence in System Settings")
                log("  2. Restart > Hold Power > Recovery Mode")
                log("  3. Terminal > mount Data volume > run rm commands")
                log("  Use 'Save Recovery Script' for the exact commands.")
            } else {
                status = .done(freedSpace: totalFreed)
                log("\nFreed \(formatBytes(totalFreed))")
            }

            scan()
        }
    }

    func generateRecoveryScript() -> String {
        let selected = modelFiles.filter { $0.isSelected }
        let paths = selected.isEmpty ? modelPaths : selected.map { $0.path }

        var script = """
        #!/bin/bash
        # Apple Intelligence Remover — run in Recovery Mode Terminal

        echo "Apple Intelligence Remover"
        echo ""

        diskutil mount "Macintosh HD - Data" 2>/dev/null || diskutil mount "Data" 2>/dev/null
        echo "Removing model files...\n"

        """

        for path in paths {
            let dataPath = path.hasPrefix("/Volumes/Data") ? path : "/Volumes/Data\(path)"
            script += """

            if [ -d "\(dataPath)" ]; then
                SIZE=$(du -sh "\(dataPath)" 2>/dev/null | cut -f1)
                echo "  Removing \((dataPath as NSString).lastPathComponent) ($SIZE)..."
                rm -rf "\(dataPath)"
                echo "  Done"
            fi

            """
        }

        script += """

        echo ""
        echo "Done. Restart your Mac."
        echo "Re-enable SIP if needed: csrutil enable"
        """
        return script
    }

    func rebootToRecovery() {
        log("Setting recovery boot flag...")
        let result = privilegedShell("nvram \"recovery-boot-mode=unused\" && shutdown -r now")
        if result.contains("error") {
            log("Failed to reboot: \(result)")
            log("You can manually reboot: shut down, then hold Power button.")
        }
    }

    func saveRecoveryScript() {
        let desktop = ("~/Desktop" as NSString).expandingTildeInPath
        let path = "\(desktop)/remove_apple_intelligence.sh"
        do {
            try generateRecoveryScript().write(toFile: path, atomically: true, encoding: .utf8)
            shell("chmod +x '\(path)'")
            log("Script saved to Desktop: remove_apple_intelligence.sh")
        } catch {
            log("Failed to save: \(error.localizedDescription)")
        }
    }

    func formatBytes(_ bytes: Int64) -> String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt.string(fromByteCount: bytes)
    }

    private func log(_ msg: String) {
        logMessages.append(msg)
    }

    private func dirSize(_ path: String) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        while let file = enumerator.nextObject() as? String {
            let full = (path as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: full),
               let s = attrs[.size] as? Int64 { total += s }
        }
        return total
    }

    @discardableResult
    private func shell(_ cmd: String) -> String {
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", cmd]
        proc.standardOutput = pipe
        proc.standardError = pipe
        do { try proc.run(); proc.waitUntilExit() }
        catch { return "Error: \(error.localizedDescription)" }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    private func privilegedShell(_ cmd: String) -> String {
        let src = "do shell script \"\(cmd)\" with administrator privileges"
        let script = NSAppleScript(source: src)
        var err: NSDictionary?
        let result = script?.executeAndReturnError(&err)
        if let err = err { return "error: \(err)" }
        return result?.stringValue ?? ""
    }
}
