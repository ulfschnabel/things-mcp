import Foundation

// Read auth token from environment
let authToken = ProcessInfo.processInfo.environment["THINGS_AUTH_TOKEN"]

// Initialize components
let thingsClient = ThingsClient(authToken: authToken)
let tools = Tools(thingsClient: thingsClient)

// Parse command line arguments
let args = CommandLine.arguments

func printUsage() {
    let usage = """
    Things MCP Server

    Usage: things-mcp [options]

    Options:
      --http [port]    Run HTTP server with SSE transport (default port: 3000)
      --stdio          Run in stdio mode (default)
      --help           Show this help message

    Environment variables:
      THINGS_AUTH_TOKEN    Auth token for update operations (optional)

    Examples:
      things-mcp                  # Run in stdio mode
      things-mcp --http           # Run HTTP server on port 3000
      things-mcp --http 8080      # Run HTTP server on port 8080
    """
    FileHandle.standardError.write(usage.data(using: .utf8)!)
}

if args.contains("--help") || args.contains("-h") {
    printUsage()
    exit(0)
}

if args.contains("--http") {
    // HTTP mode with SSE transport
    var port: UInt16 = 3000

    if let httpIndex = args.firstIndex(of: "--http"),
       httpIndex + 1 < args.count,
       let customPort = UInt16(args[httpIndex + 1]) {
        port = customPort
    }

    let httpServer = HTTPServer(tools: tools, port: port)
    do {
        try httpServer.run()
    } catch {
        FileHandle.standardError.write("Failed to start HTTP server: \(error)\n".data(using: .utf8)!)
        exit(1)
    }
} else {
    // Default: stdio mode
    let server = MCPServer(tools: tools)
    server.run()
}
