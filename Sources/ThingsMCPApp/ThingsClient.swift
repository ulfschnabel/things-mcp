import Foundation
import AppKit

class ThingsClient {
    private let authToken: String?

    init(authToken: String? = nil) {
        self.authToken = authToken
    }

    // MARK: - URL Building

    private func buildURL(command: String, params: [String: String]) -> URL? {
        var components = URLComponents()
        components.scheme = "things"
        components.host = ""
        components.path = "/\(command)"

        var queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        // Add auth token for operations that require it
        if let token = authToken, ["update", "update-project", "json"].contains(command) {
            queryItems.append(URLQueryItem(name: "auth-token", value: token))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }

    private func openURL(_ url: URL) -> Bool {
        return NSWorkspace.shared.open(url)
    }

    // MARK: - Public API

    func addTodo(
        title: String,
        notes: String? = nil,
        when: String? = nil,
        deadline: String? = nil,
        tags: [String]? = nil,
        checklistItems: [String]? = nil,
        listId: String? = nil,
        heading: String? = nil
    ) -> (success: Bool, message: String) {
        var params: [String: String] = ["title": title]

        if let notes = notes { params["notes"] = notes }
        if let when = when { params["when"] = when }
        if let deadline = deadline { params["deadline"] = deadline }
        if let tags = tags, !tags.isEmpty { params["tags"] = tags.joined(separator: ",") }
        if let checklistItems = checklistItems, !checklistItems.isEmpty {
            params["checklist-items"] = checklistItems.joined(separator: "\n")
        }
        if let listId = listId { params["list-id"] = listId }
        if let heading = heading { params["heading"] = heading }

        guard let url = buildURL(command: "add", params: params) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)
        return (success, success ? "Todo '\(title)' added successfully" : "Failed to open Things URL")
    }

    func addProject(
        title: String,
        notes: String? = nil,
        when: String? = nil,
        deadline: String? = nil,
        areaId: String? = nil,
        tags: [String]? = nil,
        todos: [[String: String]]? = nil
    ) -> (success: Bool, message: String) {
        var params: [String: String] = ["title": title]

        if let notes = notes { params["notes"] = notes }
        if let when = when { params["when"] = when }
        if let deadline = deadline { params["deadline"] = deadline }
        if let areaId = areaId { params["area-id"] = areaId }
        if let tags = tags, !tags.isEmpty { params["tags"] = tags.joined(separator: ",") }

        // Convert todos to Things format (title with checklist syntax)
        if let todos = todos, !todos.isEmpty {
            let todoTitles = todos.compactMap { $0["title"] }
            params["to-dos"] = todoTitles.joined(separator: "\n")
        }

        guard let url = buildURL(command: "add-project", params: params) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)
        return (success, success ? "Project '\(title)' added successfully" : "Failed to open Things URL")
    }

    func updateTodo(
        id: String,
        title: String? = nil,
        notes: String? = nil,
        when: String? = nil,
        deadline: String? = nil,
        tags: [String]? = nil,
        completed: Bool? = nil,
        canceled: Bool? = nil
    ) -> (success: Bool, message: String) {
        guard authToken != nil else {
            return (false, "Auth token required for update operations. Set THINGS_AUTH_TOKEN environment variable.")
        }

        var params: [String: String] = ["id": id]

        if let title = title { params["title"] = title }
        if let notes = notes { params["notes"] = notes }
        if let when = when { params["when"] = when }
        if let deadline = deadline { params["deadline"] = deadline }
        if let tags = tags { params["tags"] = tags.joined(separator: ",") }
        if let completed = completed { params["completed"] = completed ? "true" : "false" }
        if let canceled = canceled { params["canceled"] = canceled ? "true" : "false" }

        guard let url = buildURL(command: "update", params: params) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)
        return (success, success ? "Todo updated successfully" : "Failed to open Things URL")
    }

    func updateProject(
        id: String,
        title: String? = nil,
        notes: String? = nil,
        when: String? = nil,
        deadline: String? = nil,
        tags: [String]? = nil,
        completed: Bool? = nil,
        canceled: Bool? = nil
    ) -> (success: Bool, message: String) {
        guard authToken != nil else {
            return (false, "Auth token required for update operations. Set THINGS_AUTH_TOKEN environment variable.")
        }

        var params: [String: String] = ["id": id]

        if let title = title { params["title"] = title }
        if let notes = notes { params["notes"] = notes }
        if let when = when { params["when"] = when }
        if let deadline = deadline { params["deadline"] = deadline }
        if let tags = tags { params["tags"] = tags.joined(separator: ",") }
        if let completed = completed { params["completed"] = completed ? "true" : "false" }
        if let canceled = canceled { params["canceled"] = canceled ? "true" : "false" }

        guard let url = buildURL(command: "update-project", params: params) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)
        return (success, success ? "Project updated successfully" : "Failed to open Things URL")
    }

    func search(query: String) -> (success: Bool, message: String) {
        guard let url = buildURL(command: "search", params: ["query": query]) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)
        return (success, success ? "Search opened for '\(query)'" : "Failed to open Things URL")
    }

    func show(id: String) -> (success: Bool, message: String) {
        guard let url = buildURL(command: "show", params: ["id": id]) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)

        let listNames: [String: String] = [
            "today": "Today",
            "inbox": "Inbox",
            "anytime": "Anytime",
            "someday": "Someday",
            "upcoming": "Upcoming",
            "logbook": "Logbook",
            "trash": "Trash"
        ]

        let displayName = listNames[id.lowercased()] ?? id
        return (success, success ? "Showing '\(displayName)'" : "Failed to open Things URL")
    }

    func jsonBatch(operations: [[String: Any]]) -> (success: Bool, message: String) {
        guard authToken != nil else {
            return (false, "Auth token required for JSON operations. Set THINGS_AUTH_TOKEN environment variable.")
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: operations),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return (false, "Failed to serialize operations to JSON")
        }

        guard let url = buildURL(command: "json", params: ["data": jsonString]) else {
            return (false, "Failed to build URL")
        }

        let success = openURL(url)
        return (success, success ? "Batch operations executed (\(operations.count) operations)" : "Failed to open Things URL")
    }
}
