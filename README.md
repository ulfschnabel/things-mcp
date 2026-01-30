# Things MCP Server

A native Swift MCP (Model Context Protocol) server for the [Things](https://culturedcode.com/things/) task manager on macOS. Allows AI assistants like Claude to create, update, and manage todos and projects in Things.

## Features

- **Native Swift implementation** - Fast, lightweight, no dependencies
- **Two modes of operation:**
  - **stdio mode** - Standard MCP protocol for local AI tools (Claude Code, etc.)
  - **HTTP mode** - Network-accessible server with SSE transport for remote access
- **Menu bar app** - macOS menu bar application with settings UI
- **Full Things integration** via URL schemes:
  - Create todos and projects
  - Update existing items (mark complete, modify, etc.)
  - Search and navigate
  - Batch operations

## Installation

### Prerequisites

- macOS 13.0 or later
- Swift 5.10 or later
- Things 3 app installed

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/things-mcp.git
cd things-mcp

# Build release binaries
swift build -c release

# The CLI tool is at: .build/release/things-mcp
# The menu bar app is at: .build/release/ThingsMCPApp
```

### Setting up the Menu Bar App

```bash
# Copy the app bundle to Applications (optional)
cp -r ThingsMCP.app /Applications/

# Or run directly
open ThingsMCP.app
```

## Usage

### CLI Tool (stdio mode)

For use with Claude Code or other MCP clients:

```bash
# Add to ~/.mcp.json
{
  "mcpServers": {
    "things": {
      "command": "/path/to/things-mcp",
      "env": {
        "THINGS_AUTH_TOKEN": "your-token-here"
      }
    }
  }
}
```

### CLI Tool (HTTP mode)

Run as a network server:

```bash
# Start HTTP server on default port 3000
THINGS_AUTH_TOKEN="your-token" things-mcp --http

# Or specify a custom port
THINGS_AUTH_TOKEN="your-token" things-mcp --http 8080
```

### Menu Bar App

1. Launch `ThingsMCP.app`
2. Click the checklist icon in the menu bar
3. Select **Settings...** to configure:
   - **Auth Token** - Your Things URL scheme auth token
   - **Port** - Server port (default: 3333)
4. The server starts automatically

## Getting Your Auth Token

1. Open **Things** → **Settings** → **General**
2. Enable **Things URLs**
3. Click **Manage** to reveal your auth token

The auth token is required for update operations (marking todos complete, modifying items, etc.).

## Available Tools

| Tool | Description |
|------|-------------|
| `add_todo` | Create a new todo with title, notes, when, deadline, tags, checklist items |
| `add_project` | Create a new project with optional nested todos |
| `update_todo` | Update an existing todo (requires auth token) |
| `update_project` | Update an existing project (requires auth token) |
| `search` | Search Things for todos/projects |
| `show` | Navigate to a list (today, inbox, etc.) or specific item |
| `json_batch` | Execute multiple operations in batch (requires auth token) |

## API Examples

### Add a Todo

```bash
curl -X POST "http://localhost:3333/message?sessionId=test" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "id": 1,
    "params": {
      "name": "add_todo",
      "arguments": {
        "title": "Buy groceries",
        "notes": "Milk, eggs, bread",
        "when": "today",
        "tags": ["errands"]
      }
    }
  }'
```

### Mark a Todo Complete

```bash
curl -X POST "http://localhost:3333/message?sessionId=test" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "id": 1,
    "params": {
      "name": "update_todo",
      "arguments": {
        "id": "ABC123...",
        "completed": true
      }
    }
  }'
```

## Project Structure

```
things-mcp/
├── Package.swift              # Swift package manifest
├── Sources/
│   ├── ThingsMCP/            # CLI tool
│   │   ├── main.swift        # Entry point
│   │   ├── MCPServer.swift   # MCP protocol (JSON-RPC over stdio)
│   │   ├── HTTPServer.swift  # HTTP server with SSE transport
│   │   ├── ThingsClient.swift# Things URL scheme wrapper
│   │   └── Tools.swift       # MCP tool definitions
│   └── ThingsMCPApp/         # Menu bar app
│       ├── main.swift        # App entry point
│       ├── AppDelegate.swift # Menu bar UI
│       ├── SettingsWindow.swift # Settings UI
│       └── ... (shared files)
├── ThingsMCP.app/            # Built app bundle
└── README.md
```

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Things](https://culturedcode.com/things/) by Cultured Code
- [Model Context Protocol](https://modelcontextprotocol.io/) by Anthropic
