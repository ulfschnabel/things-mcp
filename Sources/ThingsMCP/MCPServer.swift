import Foundation

// MARK: - JSON-RPC Types

struct JSONRPCRequest: Codable {
    let jsonrpc: String
    let method: String
    let id: JSONRPCId?
    let params: JSONValue?
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String = "2.0"
    let id: JSONRPCId?
    let result: JSONValue?
    let error: JSONRPCError?

    init(id: JSONRPCId?, result: JSONValue) {
        self.id = id
        self.result = result
        self.error = nil
    }

    init(id: JSONRPCId?, error: JSONRPCError) {
        self.id = id
        self.result = nil
        self.error = error
    }
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
    let data: JSONValue?

    init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    static let parseError = JSONRPCError(code: -32700, message: "Parse error")
    static let invalidRequest = JSONRPCError(code: -32600, message: "Invalid Request")
    static let methodNotFound = JSONRPCError(code: -32601, message: "Method not found")
    static let invalidParams = JSONRPCError(code: -32602, message: "Invalid params")
    static let internalError = JSONRPCError(code: -32603, message: "Internal error")
}

enum JSONRPCId: Codable, Equatable {
    case string(String)
    case int(Int)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(JSONRPCId.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string, int, or null"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

enum JSONValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    subscript(key: String) -> JSONValue? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }
}

// MARK: - MCP Types

struct MCPServerInfo: Codable {
    let name: String
    let version: String
}

struct MCPCapabilities: Codable {
    let tools: [String: JSONValue]?
}

struct MCPInitializeResult: Codable {
    let protocolVersion: String
    let capabilities: MCPCapabilities
    let serverInfo: MCPServerInfo
}

struct MCPTool: Codable {
    let name: String
    let description: String
    let inputSchema: JSONValue
}

struct MCPToolsListResult: Codable {
    let tools: [MCPTool]
}

struct MCPToolResult: Codable {
    let content: [MCPContent]
    let isError: Bool?
}

struct MCPContent: Codable {
    let type: String
    let text: String
}

// MARK: - MCP Server

class MCPServer {
    private let tools: Tools
    private var initialized = false

    init(tools: Tools) {
        self.tools = tools
    }

    func run() {
        while let line = readLine() {
            guard !line.isEmpty else { continue }

            let response = handleRequest(line)
            if let response = response {
                print(response)
                fflush(stdout)
            }
        }
    }

    private func handleRequest(_ input: String) -> String? {
        guard let data = input.data(using: .utf8) else {
            return encodeResponse(JSONRPCResponse(id: nil, error: .parseError))
        }

        let decoder = JSONDecoder()
        let request: JSONRPCRequest
        do {
            request = try decoder.decode(JSONRPCRequest.self, from: data)
        } catch {
            return encodeResponse(JSONRPCResponse(id: nil, error: .parseError))
        }

        let response = processRequest(request)
        return encodeResponse(response)
    }

    private func processRequest(_ request: JSONRPCRequest) -> JSONRPCResponse {
        switch request.method {
        case "initialize":
            return handleInitialize(request)
        case "initialized":
            // Notification, no response needed but we'll acknowledge
            return JSONRPCResponse(id: request.id, result: .object([:]))
        case "tools/list":
            return handleToolsList(request)
        case "tools/call":
            return handleToolsCall(request)
        case "ping":
            return JSONRPCResponse(id: request.id, result: .object([:]))
        default:
            return JSONRPCResponse(id: request.id, error: .methodNotFound)
        }
    }

    private func handleInitialize(_ request: JSONRPCRequest) -> JSONRPCResponse {
        initialized = true

        let result = MCPInitializeResult(
            protocolVersion: "2024-11-05",
            capabilities: MCPCapabilities(tools: ["listChanged": .bool(false)]),
            serverInfo: MCPServerInfo(name: "things-mcp", version: "1.0.0")
        )

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(result),
              let jsonObject = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return JSONRPCResponse(id: request.id, error: .internalError)
        }

        return JSONRPCResponse(id: request.id, result: jsonObject)
    }

    private func handleToolsList(_ request: JSONRPCRequest) -> JSONRPCResponse {
        let toolsList = tools.listTools()
        let result = MCPToolsListResult(tools: toolsList)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(result),
              let jsonObject = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return JSONRPCResponse(id: request.id, error: .internalError)
        }

        return JSONRPCResponse(id: request.id, result: jsonObject)
    }

    private func handleToolsCall(_ request: JSONRPCRequest) -> JSONRPCResponse {
        guard let params = request.params?.objectValue,
              let toolName = params["name"]?.stringValue else {
            return JSONRPCResponse(id: request.id, error: .invalidParams)
        }

        let arguments = params["arguments"]?.objectValue ?? [:]

        let result = tools.callTool(name: toolName, arguments: arguments)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(result),
              let jsonObject = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return JSONRPCResponse(id: request.id, error: .internalError)
        }

        return JSONRPCResponse(id: request.id, result: jsonObject)
    }

    private func encodeResponse(_ response: JSONRPCResponse) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        guard let data = try? encoder.encode(response),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
