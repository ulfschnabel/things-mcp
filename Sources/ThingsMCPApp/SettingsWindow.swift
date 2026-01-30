import Cocoa

class SettingsWindowController: NSWindowController {
    private var authTokenField: NSTextField!
    private var portField: NSTextField!
    private var onSave: (() -> Void)?

    convenience init(onSave: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Things MCP Settings"
        window.center()

        self.init(window: window)
        self.onSave = onSave
        setupUI()
        loadSettings()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Auth Token Label
        let authLabel = NSTextField(labelWithString: "Auth Token:")
        authLabel.frame = NSRect(x: 20, y: 130, width: 100, height: 20)
        contentView.addSubview(authLabel)

        // Auth Token Field
        authTokenField = NSTextField(frame: NSRect(x: 120, y: 128, width: 260, height: 24))
        authTokenField.placeholderString = "Enter Things auth token"
        contentView.addSubview(authTokenField)

        // Port Label
        let portLabel = NSTextField(labelWithString: "Port:")
        portLabel.frame = NSRect(x: 20, y: 90, width: 100, height: 20)
        contentView.addSubview(portLabel)

        // Port Field
        portField = NSTextField(frame: NSRect(x: 120, y: 88, width: 100, height: 24))
        portField.placeholderString = "3333"
        contentView.addSubview(portField)

        // Help text
        let helpText = NSTextField(wrappingLabelWithString: "Get your auth token from Things → Settings → General → Enable Things URLs → Manage")
        helpText.frame = NSRect(x: 20, y: 45, width: 360, height: 35)
        helpText.font = NSFont.systemFont(ofSize: 11)
        helpText.textColor = .secondaryLabelColor
        contentView.addSubview(helpText)

        // Cancel Button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelButton.frame = NSRect(x: 200, y: 10, width: 80, height: 30)
        cancelButton.bezelStyle = .rounded
        contentView.addSubview(cancelButton)

        // Save Button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveButton.frame = NSRect(x: 290, y: 10, width: 80, height: 30)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        contentView.addSubview(saveButton)
    }

    private func loadSettings() {
        authTokenField.stringValue = Settings.shared.authToken
        portField.stringValue = String(Settings.shared.port)
    }

    @objc private func cancelClicked() {
        window?.close()
    }

    @objc private func saveClicked() {
        Settings.shared.authToken = authTokenField.stringValue

        if let port = UInt16(portField.stringValue), port > 0 {
            Settings.shared.port = port
        }

        onSave?()
        window?.close()
    }
}

// MARK: - Settings Storage

class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let authToken = "thingsmcp.authToken"
        static let port = "thingsmcp.port"
    }

    var authToken: String {
        get {
            // First check UserDefaults, then fall back to environment variable
            if let saved = defaults.string(forKey: Keys.authToken), !saved.isEmpty {
                return saved
            }
            return ProcessInfo.processInfo.environment["THINGS_AUTH_TOKEN"] ?? ""
        }
        set {
            defaults.set(newValue, forKey: Keys.authToken)
        }
    }

    var port: UInt16 {
        get {
            let saved = defaults.integer(forKey: Keys.port)
            return saved > 0 ? UInt16(saved) : 3333
        }
        set {
            defaults.set(Int(newValue), forKey: Keys.port)
        }
    }
}
