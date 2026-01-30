import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var httpServer: HTTPServer?
    private var isRunning = false
    private var settingsWindowController: SettingsWindowController?

    private var currentPort: UInt16 {
        return Settings.shared.port
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Things MCP")
            button.image?.isTemplate = true
        }

        updateMenu()

        // Auto-start the server
        startServer()
    }

    private func updateMenu() {
        let menu = NSMenu()

        // Status
        let statusTitle = isRunning ? "● Server Running" : "○ Server Stopped"
        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        if isRunning {
            let portItem = NSMenuItem(title: "Port: \(currentPort)", action: nil, keyEquivalent: "")
            portItem.isEnabled = false
            menu.addItem(portItem)

            // Get IP address
            if let ip = getLocalIPAddress() {
                let urlItem = NSMenuItem(title: "URL: http://\(ip):\(currentPort)", action: #selector(copyURL), keyEquivalent: "c")
                menu.addItem(urlItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Start/Stop
        if isRunning {
            menu.addItem(NSMenuItem(title: "Stop Server", action: #selector(stopServer), keyEquivalent: "s"))
        } else {
            menu.addItem(NSMenuItem(title: "Start Server", action: #selector(startServer), keyEquivalent: "s"))
        }

        // Restart (only shown when running)
        if isRunning {
            menu.addItem(NSMenuItem(title: "Restart Server", action: #selector(restartServer), keyEquivalent: "r"))
        }

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        self.statusItem.menu = menu
    }

    @objc private func startServer() {
        guard !isRunning else { return }

        let authToken = Settings.shared.authToken
        let thingsClient = ThingsClient(authToken: authToken.isEmpty ? nil : authToken)
        let tools = Tools(thingsClient: thingsClient)

        httpServer = HTTPServer(tools: tools, port: currentPort)

        do {
            try httpServer?.start()
            isRunning = true
            updateStatusIcon()
            updateMenu()
        } catch {
            showError("Failed to start server: \(error.localizedDescription)")
        }
    }

    @objc private func stopServer() {
        httpServer = nil
        isRunning = false
        updateStatusIcon()
        updateMenu()
    }

    @objc private func restartServer() {
        stopServer()
        // Small delay to ensure port is released
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startServer()
        }
    }

    @objc private func copyURL() {
        if let ip = getLocalIPAddress() {
            let url = "http://\(ip):\(currentPort)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url, forType: .string)
        }
    }

    @objc private func openSettings() {
        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)

        settingsWindowController = SettingsWindowController { [weak self] in
            // Settings were saved - restart server if running to apply new settings
            if self?.isRunning == true {
                self?.restartServer()
            }
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        stopServer()
        NSApplication.shared.terminate(nil)
    }

    private func updateStatusIcon() {
        if let button = statusItem.button {
            let symbolName = isRunning ? "checklist.checked" : "checklist"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Things MCP")
            button.image?.isTemplate = true
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Things MCP Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}
