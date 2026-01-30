import Foundation
import Network

/// HTTP Server with SSE transport for MCP
class HTTPServer {
    private let tools: Tools
    private let port: UInt16
    private var listener: NWListener?
    private var connections: [UUID: ClientConnection] = [:]
    private let queue = DispatchQueue(label: "httpserver", qos: .userInitiated)

    init(tools: Tools, port: UInt16) {
        self.tools = tools
        self.port = port
    }

    func start() throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)

        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let port = self?.listener?.port {
                    FileHandle.standardError.write("Things MCP server listening on http://0.0.0.0:\(port.rawValue)\n".data(using: .utf8)!)
                    FileHandle.standardError.write("SSE endpoint: http://0.0.0.0:\(port.rawValue)/sse\n".data(using: .utf8)!)
                    FileHandle.standardError.write("Message endpoint: POST http://0.0.0.0:\(port.rawValue)/message?sessionId=<id>\n".data(using: .utf8)!)
                }
            case .failed(let error):
                FileHandle.standardError.write("Server failed: \(error)\n".data(using: .utf8)!)
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.start(queue: queue)
    }

    func run() throws {
        try start()
        dispatchMain()
    }

    private func handleConnection(_ connection: NWConnection) {
        let clientId = UUID()
        let client = ClientConnection(id: clientId, connection: connection, tools: tools)

        queue.async { [weak self] in
            self?.connections[clientId] = client
        }

        client.onClose = { [weak self] in
            self?.queue.async {
                self?.connections.removeValue(forKey: clientId)
            }
        }

        client.start()
    }
}

/// Represents a single client connection
class ClientConnection {
    let id: UUID
    let connection: NWConnection
    let tools: Tools
    var onClose: (() -> Void)?

    private var sseSessionId: String?
    private var isSSE = false
    private var buffer = Data()

    init(id: UUID, connection: NWConnection, tools: Tools) {
        self.id = id
        self.connection = connection
        self.tools = tools
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveData()
            case .failed, .cancelled:
                self?.onClose?()
            default:
                break
            }
        }
        connection.start(queue: DispatchQueue(label: "client-\(id)"))
    }

    private func receiveData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.buffer.append(data)
                self?.processBuffer()
            }

            if isComplete || error != nil {
                self?.connection.cancel()
                self?.onClose?()
            } else {
                self?.receiveData()
            }
        }
    }

    private func processBuffer() {
        guard let request = parseHTTPRequest() else { return }

        if request.path == "/sse" || request.path == "/sse/" {
            handleSSE(request)
        } else if request.path.hasPrefix("/message") && request.method == "POST" {
            handleMessage(request)
        } else if request.path == "/" || request.path == "/health" {
            handleHealth(request)
        } else {
            sendHTTPResponse(status: 404, body: "Not Found")
        }
    }

    private func parseHTTPRequest() -> HTTPRequest? {
        guard let headerEnd = buffer.range(of: "\r\n\r\n".data(using: .utf8)!) else {
            return nil
        }

        let headerData = buffer.subdata(in: 0..<headerEnd.lowerBound)
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }

        let method = parts[0]
        let fullPath = parts[1]

        // Parse path and query string
        let pathComponents = fullPath.components(separatedBy: "?")
        let path = pathComponents[0]
        var queryParams: [String: String] = [:]

        if pathComponents.count > 1 {
            let queryString = pathComponents[1]
            for param in queryString.components(separatedBy: "&") {
                let kv = param.components(separatedBy: "=")
                if kv.count == 2 {
                    queryParams[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
                }
            }
        }

        // Parse headers
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let headerParts = line.components(separatedBy: ": ")
            if headerParts.count == 2 {
                headers[headerParts[0].lowercased()] = headerParts[1]
            }
        }

        // Get body if Content-Length present
        var body: Data? = nil
        if let contentLengthStr = headers["content-length"],
           let contentLength = Int(contentLengthStr) {
            let bodyStart = headerEnd.upperBound
            let bodyEnd = bodyStart + contentLength
            if buffer.count >= bodyEnd {
                body = buffer.subdata(in: bodyStart..<bodyEnd)
                buffer.removeSubrange(0..<bodyEnd)
            } else {
                // Need more data
                return nil
            }
        } else {
            buffer.removeSubrange(0..<headerEnd.upperBound)
        }

        return HTTPRequest(method: method, path: path, queryParams: queryParams, headers: headers, body: body)
    }

    private func handleSSE(_ request: HTTPRequest) {
        isSSE = true
        sseSessionId = UUID().uuidString

        let headers = """
        HTTP/1.1 200 OK\r
        Content-Type: text/event-stream\r
        Cache-Control: no-cache\r
        Connection: keep-alive\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Headers: Content-Type\r
        \r

        """

        connection.send(content: headers.data(using: .utf8), completion: .contentProcessed { [weak self] _ in
            // Send endpoint event with session ID
            guard let self = self, let sessionId = self.sseSessionId else { return }
            let endpointEvent = "event: endpoint\ndata: /message?sessionId=\(sessionId)\n\n"
            self.connection.send(content: endpointEvent.data(using: .utf8), completion: .contentProcessed { _ in })
        })
    }

    private func handleMessage(_ request: HTTPRequest) {
        guard let sessionId = request.queryParams["sessionId"] else {
            sendHTTPResponse(status: 400, body: "{\"error\": \"Missing sessionId\"}")
            return
        }

        guard let body = request.body,
              let bodyString = String(data: body, encoding: .utf8) else {
            sendHTTPResponse(status: 400, body: "{\"error\": \"Missing body\"}")
            return
        }

        // Process the JSON-RPC request
        let response = processJSONRPC(bodyString)

        // Send response with CORS headers
        let responseHeaders = """
        HTTP/1.1 202 Accepted\r
        Content-Type: application/json\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Headers: Content-Type\r
        Content-Length: \(response.utf8.count)\r
        \r

        """
        connection.send(content: (responseHeaders + response).data(using: .utf8), completion: .contentProcessed { [weak self] _ in
            self?.connection.cancel()
        })

        // Also send response via SSE to any connected clients with this session
        // In a full implementation, you'd maintain a session registry
    }

    private func handleHealth(_ request: HTTPRequest) {
        let body = "{\"status\": \"ok\", \"server\": \"things-mcp\", \"version\": \"1.0.0\"}"
        sendHTTPResponse(status: 200, body: body, contentType: "application/json")
    }

    private func processJSONRPC(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else {
            return encodeError(.parseError, id: nil)
        }

        let decoder = JSONDecoder()
        let request: JSONRPCRequest
        do {
            request = try decoder.decode(JSONRPCRequest.self, from: data)
        } catch {
            return encodeError(.parseError, id: nil)
        }

        let response = processRequest(request)
        return encodeResponse(response)
    }

    private func processRequest(_ request: JSONRPCRequest) -> JSONRPCResponse {
        switch request.method {
        case "initialize":
            return handleInitialize(request)
        case "initialized":
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

    private func sendHTTPResponse(status: Int, body: String, contentType: String = "text/plain") {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 202: statusText = "Accepted"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        default: statusText = "Unknown"
        }

        let response = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Headers: Content-Type\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { [weak self] _ in
            self?.connection.cancel()
        })
    }

    private func encodeResponse(_ response: JSONRPCResponse) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(response),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Internal error\"}}"
        }
        return string
    }

    private func encodeError(_ error: JSONRPCError, id: JSONRPCId?) -> String {
        let response = JSONRPCResponse(id: id, error: error)
        return encodeResponse(response)
    }

    func sendSSEEvent(event: String, data: String) {
        guard isSSE else { return }
        let message = "event: \(event)\ndata: \(data)\n\n"
        connection.send(content: message.data(using: .utf8), completion: .contentProcessed { _ in })
    }
}

struct HTTPRequest {
    let method: String
    let path: String
    let queryParams: [String: String]
    let headers: [String: String]
    let body: Data?
}
