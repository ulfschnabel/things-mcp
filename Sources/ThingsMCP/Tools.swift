import Foundation

class Tools {
    private let thingsClient: ThingsClient

    init(thingsClient: ThingsClient) {
        self.thingsClient = thingsClient
    }

    func listTools() -> [MCPTool] {
        return [
            MCPTool(
                name: "add_todo",
                description: "Create a new todo in Things. Returns success status.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "title": .object([
                            "type": .string("string"),
                            "description": .string("The title of the todo (required)")
                        ]),
                        "notes": .object([
                            "type": .string("string"),
                            "description": .string("Notes or description for the todo")
                        ]),
                        "when": .object([
                            "type": .string("string"),
                            "description": .string("When to schedule: 'today', 'tomorrow', 'evening', 'someday', a date (YYYY-MM-DD), or datetime (YYYY-MM-DD@HH:MM)")
                        ]),
                        "deadline": .object([
                            "type": .string("string"),
                            "description": .string("Deadline date in YYYY-MM-DD format")
                        ]),
                        "tags": .object([
                            "type": .string("array"),
                            "items": .object(["type": .string("string")]),
                            "description": .string("Array of tag names to apply")
                        ]),
                        "checklist_items": .object([
                            "type": .string("array"),
                            "items": .object(["type": .string("string")]),
                            "description": .string("Array of checklist item titles")
                        ]),
                        "list_id": .object([
                            "type": .string("string"),
                            "description": .string("ID of the project or area to add the todo to")
                        ]),
                        "heading": .object([
                            "type": .string("string"),
                            "description": .string("Name of a heading within a project to add the todo under")
                        ])
                    ]),
                    "required": .array([.string("title")])
                ])
            ),
            MCPTool(
                name: "add_project",
                description: "Create a new project in Things. Returns success status.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "title": .object([
                            "type": .string("string"),
                            "description": .string("The title of the project (required)")
                        ]),
                        "notes": .object([
                            "type": .string("string"),
                            "description": .string("Notes or description for the project")
                        ]),
                        "when": .object([
                            "type": .string("string"),
                            "description": .string("When to schedule: 'today', 'tomorrow', 'evening', 'someday', a date (YYYY-MM-DD), or datetime (YYYY-MM-DD@HH:MM)")
                        ]),
                        "deadline": .object([
                            "type": .string("string"),
                            "description": .string("Deadline date in YYYY-MM-DD format")
                        ]),
                        "area_id": .object([
                            "type": .string("string"),
                            "description": .string("ID of the area to add the project to")
                        ]),
                        "tags": .object([
                            "type": .string("array"),
                            "items": .object(["type": .string("string")]),
                            "description": .string("Array of tag names to apply")
                        ]),
                        "todos": .object([
                            "type": .string("array"),
                            "items": .object([
                                "type": .string("object"),
                                "properties": .object([
                                    "title": .object(["type": .string("string")])
                                ])
                            ]),
                            "description": .string("Array of todo objects to create within the project")
                        ])
                    ]),
                    "required": .array([.string("title")])
                ])
            ),
            MCPTool(
                name: "update_todo",
                description: "Update an existing todo in Things. Requires THINGS_AUTH_TOKEN environment variable.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object([
                            "type": .string("string"),
                            "description": .string("The ID of the todo to update (required)")
                        ]),
                        "title": .object([
                            "type": .string("string"),
                            "description": .string("New title for the todo")
                        ]),
                        "notes": .object([
                            "type": .string("string"),
                            "description": .string("New notes for the todo")
                        ]),
                        "when": .object([
                            "type": .string("string"),
                            "description": .string("When to schedule: 'today', 'tomorrow', 'evening', 'someday', a date (YYYY-MM-DD), or datetime (YYYY-MM-DD@HH:MM)")
                        ]),
                        "deadline": .object([
                            "type": .string("string"),
                            "description": .string("Deadline date in YYYY-MM-DD format")
                        ]),
                        "tags": .object([
                            "type": .string("array"),
                            "items": .object(["type": .string("string")]),
                            "description": .string("Array of tag names (replaces existing tags)")
                        ]),
                        "completed": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to mark as completed")
                        ]),
                        "canceled": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to cancel the todo")
                        ])
                    ]),
                    "required": .array([.string("id")])
                ])
            ),
            MCPTool(
                name: "update_project",
                description: "Update an existing project in Things. Requires THINGS_AUTH_TOKEN environment variable.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object([
                            "type": .string("string"),
                            "description": .string("The ID of the project to update (required)")
                        ]),
                        "title": .object([
                            "type": .string("string"),
                            "description": .string("New title for the project")
                        ]),
                        "notes": .object([
                            "type": .string("string"),
                            "description": .string("New notes for the project")
                        ]),
                        "when": .object([
                            "type": .string("string"),
                            "description": .string("When to schedule: 'today', 'tomorrow', 'evening', 'someday', a date (YYYY-MM-DD), or datetime (YYYY-MM-DD@HH:MM)")
                        ]),
                        "deadline": .object([
                            "type": .string("string"),
                            "description": .string("Deadline date in YYYY-MM-DD format")
                        ]),
                        "tags": .object([
                            "type": .string("array"),
                            "items": .object(["type": .string("string")]),
                            "description": .string("Array of tag names (replaces existing tags)")
                        ]),
                        "completed": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to mark as completed")
                        ]),
                        "canceled": .object([
                            "type": .string("boolean"),
                            "description": .string("Set to true to cancel the project")
                        ])
                    ]),
                    "required": .array([.string("id")])
                ])
            ),
            MCPTool(
                name: "search",
                description: "Search for todos, projects, or tags in Things. Opens the search results in Things.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "query": .object([
                            "type": .string("string"),
                            "description": .string("The search query (required)")
                        ])
                    ]),
                    "required": .array([.string("query")])
                ])
            ),
            MCPTool(
                name: "show",
                description: "Navigate to a specific list or item in Things. Use predefined list IDs (today, inbox, anytime, someday, upcoming, logbook, trash) or a specific item ID.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object([
                            "type": .string("string"),
                            "description": .string("The list or item ID to show (required). Predefined lists: today, inbox, anytime, someday, upcoming, logbook, trash")
                        ])
                    ]),
                    "required": .array([.string("id")])
                ])
            ),
            MCPTool(
                name: "json_batch",
                description: "Execute multiple operations in a single batch using Things JSON format. Requires THINGS_AUTH_TOKEN environment variable.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "operations": .object([
                            "type": .string("array"),
                            "description": .string("Array of operation objects following Things JSON format"),
                            "items": .object([
                                "type": .string("object")
                            ])
                        ])
                    ]),
                    "required": .array([.string("operations")])
                ])
            )
        ]
    }

    func callTool(name: String, arguments: [String: JSONValue]) -> MCPToolResult {
        switch name {
        case "add_todo":
            return handleAddTodo(arguments)
        case "add_project":
            return handleAddProject(arguments)
        case "update_todo":
            return handleUpdateTodo(arguments)
        case "update_project":
            return handleUpdateProject(arguments)
        case "search":
            return handleSearch(arguments)
        case "show":
            return handleShow(arguments)
        case "json_batch":
            return handleJsonBatch(arguments)
        default:
            return MCPToolResult(
                content: [MCPContent(type: "text", text: "Unknown tool: \(name)")],
                isError: true
            )
        }
    }

    // MARK: - Tool Handlers

    private func handleAddTodo(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let title = args["title"]?.stringValue else {
            return errorResult("Missing required parameter: title")
        }

        let notes = args["notes"]?.stringValue
        let when = args["when"]?.stringValue
        let deadline = args["deadline"]?.stringValue
        let tags = args["tags"]?.arrayValue?.compactMap { $0.stringValue }
        let checklistItems = args["checklist_items"]?.arrayValue?.compactMap { $0.stringValue }
        let listId = args["list_id"]?.stringValue
        let heading = args["heading"]?.stringValue

        let result = thingsClient.addTodo(
            title: title,
            notes: notes,
            when: when,
            deadline: deadline,
            tags: tags,
            checklistItems: checklistItems,
            listId: listId,
            heading: heading
        )

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    private func handleAddProject(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let title = args["title"]?.stringValue else {
            return errorResult("Missing required parameter: title")
        }

        let notes = args["notes"]?.stringValue
        let when = args["when"]?.stringValue
        let deadline = args["deadline"]?.stringValue
        let areaId = args["area_id"]?.stringValue
        let tags = args["tags"]?.arrayValue?.compactMap { $0.stringValue }

        var todos: [[String: String]]? = nil
        if let todosArray = args["todos"]?.arrayValue {
            todos = todosArray.compactMap { todoValue -> [String: String]? in
                guard let todoObj = todoValue.objectValue,
                      let todoTitle = todoObj["title"]?.stringValue else {
                    return nil
                }
                return ["title": todoTitle]
            }
        }

        let result = thingsClient.addProject(
            title: title,
            notes: notes,
            when: when,
            deadline: deadline,
            areaId: areaId,
            tags: tags,
            todos: todos
        )

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    private func handleUpdateTodo(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let id = args["id"]?.stringValue else {
            return errorResult("Missing required parameter: id")
        }

        let title = args["title"]?.stringValue
        let notes = args["notes"]?.stringValue
        let when = args["when"]?.stringValue
        let deadline = args["deadline"]?.stringValue
        let tags = args["tags"]?.arrayValue?.compactMap { $0.stringValue }
        let completed = args["completed"]?.boolValue
        let canceled = args["canceled"]?.boolValue

        let result = thingsClient.updateTodo(
            id: id,
            title: title,
            notes: notes,
            when: when,
            deadline: deadline,
            tags: tags,
            completed: completed,
            canceled: canceled
        )

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    private func handleUpdateProject(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let id = args["id"]?.stringValue else {
            return errorResult("Missing required parameter: id")
        }

        let title = args["title"]?.stringValue
        let notes = args["notes"]?.stringValue
        let when = args["when"]?.stringValue
        let deadline = args["deadline"]?.stringValue
        let tags = args["tags"]?.arrayValue?.compactMap { $0.stringValue }
        let completed = args["completed"]?.boolValue
        let canceled = args["canceled"]?.boolValue

        let result = thingsClient.updateProject(
            id: id,
            title: title,
            notes: notes,
            when: when,
            deadline: deadline,
            tags: tags,
            completed: completed,
            canceled: canceled
        )

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    private func handleSearch(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let query = args["query"]?.stringValue else {
            return errorResult("Missing required parameter: query")
        }

        let result = thingsClient.search(query: query)

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    private func handleShow(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let id = args["id"]?.stringValue else {
            return errorResult("Missing required parameter: id")
        }

        let result = thingsClient.show(id: id)

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    private func handleJsonBatch(_ args: [String: JSONValue]) -> MCPToolResult {
        guard let operationsArray = args["operations"]?.arrayValue else {
            return errorResult("Missing required parameter: operations")
        }

        // Convert JSONValue array to [[String: Any]]
        let operations: [[String: Any]] = operationsArray.compactMap { jsonValueToAny($0) as? [String: Any] }

        if operations.isEmpty {
            return errorResult("No valid operations provided")
        }

        let result = thingsClient.jsonBatch(operations: operations)

        return MCPToolResult(
            content: [MCPContent(type: "text", text: result.message)],
            isError: !result.success
        )
    }

    // MARK: - Helpers

    private func errorResult(_ message: String) -> MCPToolResult {
        return MCPToolResult(
            content: [MCPContent(type: "text", text: message)],
            isError: true
        )
    }

    private func jsonValueToAny(_ value: JSONValue) -> Any {
        switch value {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .null: return NSNull()
        case .array(let arr): return arr.map { jsonValueToAny($0) }
        case .object(let obj): return obj.mapValues { jsonValueToAny($0) }
        }
    }
}
