import Cocoa

class LogsWindowController {
    private var window: NSWindow?
    private var textView: NSTextView?
    private var scrollView: NSScrollView?

    func showWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Things MCP Server Logs"
        window.center()
        window.isReleasedWhenClosed = false

        // Create content view
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        // Create scroll view with text view
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 50, width: 680, height: 440))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .bezelBorder

        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0)
        textView.textColor = NSColor(calibratedWhite: 0.9, alpha: 1.0)
        textView.isRichText = true

        scrollView.documentView = textView

        // Create buttons
        let clearButton = NSButton(frame: NSRect(x: 10, y: 10, width: 80, height: 30))
        clearButton.title = "Clear"
        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearLogs)

        let autoScrollCheckbox = NSButton(frame: NSRect(x: 100, y: 10, width: 120, height: 30))
        autoScrollCheckbox.setButtonType(.switch)
        autoScrollCheckbox.title = "Auto-scroll"
        autoScrollCheckbox.state = .on
        autoScrollCheckbox.tag = 1

        contentView.addSubview(scrollView)
        contentView.addSubview(clearButton)
        contentView.addSubview(autoScrollCheckbox)

        window.contentView = contentView
        self.window = window
        self.textView = textView
        self.scrollView = scrollView

        // Load existing logs
        loadExistingLogs()

        // Subscribe to new logs
        Logger.shared.onNewEntry = { [weak self] entry in
            self?.appendLog(entry)
        }

        // Make sure window appears on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let newX = screenFrame.midX - windowFrame.width / 2
            let newY = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: newX, y: newY))
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func loadExistingLogs() {
        let logs = Logger.shared.getAll()
        for entry in logs {
            appendLog(entry, scroll: false)
        }
        scrollToBottom()
    }

    private func appendLog(_ entry: LogEntry, scroll: Bool = true) {
        guard let textView = textView else { return }

        let attributedString = NSMutableAttributedString()

        // Timestamp
        let timeString = "[\(formatTime(entry.timestamp))] "
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.gray,
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        ]
        attributedString.append(NSAttributedString(string: timeString, attributes: timeAttrs))

        // Level
        let levelColor: NSColor
        switch entry.level {
        case .debug: levelColor = NSColor.systemGray
        case .info: levelColor = NSColor.systemBlue
        case .warning: levelColor = NSColor.systemOrange
        case .error: levelColor = NSColor.systemRed
        }

        let levelString = "[\(entry.level.rawValue)] "
        let levelAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: levelColor,
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        ]
        attributedString.append(NSAttributedString(string: levelString, attributes: levelAttrs))

        // Message
        let messageAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(calibratedWhite: 0.9, alpha: 1.0),
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        ]
        attributedString.append(NSAttributedString(string: entry.message + "\n", attributes: messageAttrs))

        textView.textStorage?.append(attributedString)

        if scroll {
            scrollToBottomIfEnabled()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    private func scrollToBottom() {
        guard let textView = textView else { return }
        textView.scrollToEndOfDocument(nil)
    }

    private func scrollToBottomIfEnabled() {
        guard let window = window,
              let contentView = window.contentView else { return }

        // Find the auto-scroll checkbox by tag
        for subview in contentView.subviews {
            if let checkbox = subview as? NSButton, checkbox.tag == 1 {
                if checkbox.state == .on {
                    scrollToBottom()
                }
                break
            }
        }
    }

    @objc private func clearLogs() {
        Logger.shared.clear()
        textView?.string = ""
    }
}
