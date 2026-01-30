import Foundation

/// Centralized logger for the MCP server
class Logger {
    static let shared = Logger()

    private var logs: [LogEntry] = []
    private let maxEntries = 1000
    private let queue = DispatchQueue(label: "logger")

    var onNewEntry: ((LogEntry) -> Void)?

    private init() {}

    func log(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        queue.async {
            self.logs.append(entry)
            if self.logs.count > self.maxEntries {
                self.logs.removeFirst(self.logs.count - self.maxEntries)
            }
            DispatchQueue.main.async {
                self.onNewEntry?(entry)
            }
        }
    }

    func info(_ message: String) {
        log(message, level: .info)
    }

    func debug(_ message: String) {
        log(message, level: .debug)
    }

    func error(_ message: String) {
        log(message, level: .error)
    }

    func warning(_ message: String) {
        log(message, level: .warning)
    }

    func getAll() -> [LogEntry] {
        return queue.sync { logs }
    }

    func clear() {
        queue.async {
            self.logs.removeAll()
        }
    }
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let message: String

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var formatted: String {
        let time = LogEntry.formatter.string(from: timestamp)
        return "[\(time)] [\(level.rawValue)] \(message)"
    }
}
