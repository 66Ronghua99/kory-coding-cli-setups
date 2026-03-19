---
name: use-kimi-cli
description: Delegate coding tasks to Kimi Code CLI from other AI agents. Use when you need to (1) spawn a subagent for complex file operations, (2) execute multi-step coding tasks with tool use, (3) leverage Kimi's web search and subagent capabilities, or (4) integrate Kimi Code CLI into your agent workflow. Supports subprocess calls, ACP protocol, and MCP server modes.
---

# Use Kimi Code CLI

Delegate coding tasks to Kimi Code CLI from other AI agents or systems.

## Overview

Kimi Code CLI is a powerful coding agent with capabilities including:
- File operations (read/write/grep/glob)
- Shell command execution
- Web search and URL fetching
- Subagent spawning for parallel tasks
- MCP (Model Context Protocol) tool integration

This skill provides three integration methods for calling Kimi Code CLI from other agents.

## Method 1: Subprocess (Recommended for Simple Tasks)

Direct CLI invocation using `--print` mode for non-interactive execution.

### Basic Usage

```bash
# Simple task execution
kimi --print --quiet "Your task description here"

# With working directory
kimi --print --quiet -w /path/to/project "Your task"

# With additional directories in scope
kimi --print --quiet -w /path/to/project --add-dir /path/to/shared "Your task"

# Enable YOLO mode (auto-approve all actions)
kimi --print --quiet -y "Your task"

# Use specific model
kimi --print --quiet -m "moonshot-v1-32k" "Your task"
```

### When to Use

- One-off tasks
- Simple file operations
- Tasks that don't need session persistence
- Quick delegation from another agent

### Best Practices

1. **Use `--quiet` for clean output** - Returns only the final response
2. **Set working directory explicitly** - Use `-w` to ensure correct context
3. **Enable YOLO mode for trusted tasks** - Use `-y` when you trust the task
4. **Handle errors** - Check exit codes (0 = success, non-zero = error)

### Example: Python Wrapper

```python
import subprocess
import json

def call_kimi(task: str, work_dir: str = None, yolo: bool = False) -> str:
    """Call Kimi Code CLI as a subagent."""
    cmd = ["kimi", "--print", "--quiet"]
    
    if work_dir:
        cmd.extend(["-w", work_dir])
    if yolo:
        cmd.append("-y")
    
    cmd.extend(["--prompt", task])
    
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=300  # 5 minute timeout
    )
    
    if result.returncode != 0:
        raise RuntimeError(f"Kimi failed: {result.stderr}")
    
    return result.stdout

# Usage
response = call_kimi(
    "Find all TODO comments in the codebase",
    work_dir="/path/to/project",
    yolo=True
)
print(response)
```

## Method 2: ACP Protocol (Multi-Session)

ACP (Agent Client Protocol) enables multi-session communication with Kimi Code CLI.

### Starting ACP Server

```bash
# Start ACP server (stdio transport)
kimi acp

# ACP server supports JSON-RPC style communication
```

### ACP Protocol Format

ACP uses JSON-RPC 2.0 style messages over stdio:

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "agent/request",
  "params": {
    "session_id": "optional-session-id",
    "work_dir": "/path/to/project",
    "prompt": "Your task description",
    "yolo": false
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": "Task completion response",
    "session_id": "session-uuid"
  }
}
```

### When to Use

- Long-running sessions
- Multi-turn conversations
- IDE integrations
- Concurrent task processing

### Example: Node.js ACP Client

```javascript
const { spawn } = require('child_process');

class KimiACPClient {
  constructor() {
    this.process = spawn('kimi', ['acp']);
    this.requestId = 0;
    this.pendingRequests = new Map();
    
    this.process.stdout.on('data', (data) => {
      const lines = data.toString().trim().split('\n');
      for (const line of lines) {
        try {
          const response = JSON.parse(line);
          const pending = this.pendingRequests.get(response.id);
          if (pending) {
            pending.resolve(response);
            this.pendingRequests.delete(response.id);
          }
        } catch (e) {
          console.error('Failed to parse response:', line);
        }
      }
    });
  }

  async request(prompt, options = {}) {
    const id = ++this.requestId;
    const request = {
      jsonrpc: '2.0',
      id,
      method: 'agent/request',
      params: {
        prompt,
        ...options
      }
    };
    
    return new Promise((resolve, reject) => {
      this.pendingRequests.set(id, { resolve, reject });
      this.process.stdin.write(JSON.stringify(request) + '\n');
      
      // Timeout after 5 minutes
      setTimeout(() => {
        if (this.pendingRequests.has(id)) {
          this.pendingRequests.delete(id);
          reject(new Error('Request timeout'));
        }
      }, 300000);
    });
  }

  close() {
    this.process.kill();
  }
}

// Usage
const client = new KimiACPClient();
const result = await client.request("Analyze this codebase structure", {
  work_dir: "/path/to/project"
});
console.log(result.result.content);
client.close();
```

## Method 3: MCP Server (Standard Protocol)

Kimi Code CLI can act as an MCP server or connect to external MCP servers.

### As MCP Client

```bash
# Add MCP servers to Kimi
kimi mcp add --transport http my-server https://api.example.com/mcp

# Run Kimi with MCP tools available
kimi --mcp-config-file /path/to/mcp.json
```

### MCP Configuration

```json
{
  "mcpServers": {
    "my-service": {
      "url": "https://mcp.example.com/mcp",
      "headers": {
        "Authorization": "Bearer token"
      }
    }
  }
}
```

## Task Delegation Patterns

### Pattern 1: Simple File Operations

```bash
# Delegate file analysis
kimi --print --quiet "Find all functions longer than 50 lines in src/"

# Delegate refactoring
kimi --print --quiet "Rename all occurrences of 'oldName' to 'newName'"

# Delegate code review
kimi --print --quiet "Review the changes in git diff and provide feedback"
```

### Pattern 2: Parallel Subagent Tasks

When delegating to Kimi, you can ask it to spawn subagents:

```bash
kimi --print --quiet "Analyze these 5 files in parallel using subagents: file1.py, file2.py, ..."
```

### Pattern 3: Multi-Step Workflows

```bash
# Step 1: Analyze
kimi --print --quiet "Analyze the project structure and identify main modules"

# Step 2: Execute based on analysis
kimi --print --quiet "Based on the module structure, add error handling to all API endpoints"
```

### Pattern 4: Web-Assisted Tasks

```bash
# Kimi can search the web
kimi --print --quiet "Search for the latest React best practices and update our codebase accordingly"
```

## Integration Examples

### Claude Code Integration

```python
# In your Claude Code session, call Kimi for specialized tasks

def delegate_to_kimi(task: str, project_path: str) -> str:
    """Delegate a task to Kimi Code CLI."""
    import subprocess
    
    result = subprocess.run(
        ["kimi", "--print", "--quiet", "-w", project_path, "-y", task],
        capture_output=True,
        text=True,
        timeout=600
    )
    
    return result.stdout if result.returncode == 0 else f"Error: {result.stderr}"

# Use it
result = delegate_to_kimi(
    "Optimize all database queries in the models/ directory",
    "/home/user/myproject"
)
print(result)
```

### GitHub Actions Integration

```yaml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Kimi CLI
        run: pip install kimi-cli
        
      - name: AI Review
        env:
          MOONSHOT_API_KEY: ${{ secrets.MOONSHOT_API_KEY }}
        run: |
          kimi --print --quiet \
            "Review this PR for code quality, security issues, and best practices" \
            > review_comment.md
```

### VS Code Extension Integration

```typescript
// VS Code extension calling Kimi
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function callKimi(task: string, workspacePath: string): Promise<string> {
  const { stdout } = await execAsync(
    `kimi --print --quiet -w "${workspacePath}" "${task.replace(/"/g, '\\"')}"`,
    { timeout: 300000 }
  );
  return stdout;
}

// Register command
vscode.commands.registerCommand('extension.askKimi', async () => {
  const task = await vscode.window.showInputBox({
    prompt: 'What should Kimi do?'
  });
  
  if (task) {
    const workspacePath = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
    const result = await callKimi(task, workspacePath);
    vscode.window.showInformationMessage(result);
  }
});
```

## Environment Setup

### Required Environment Variables

```bash
# API Key (required)
export MOONSHOT_API_KEY="your-api-key"

# Optional: Default model
export KIMI_MODEL="moonshot-v1-32k"

# Optional: Config directory
export KIMI_CONFIG_DIR="~/.kimi"
```

### Configuration File

```toml
# ~/.kimi/config.toml
model = "moonshot-v1-32k"
thinking = true

[provider.moonshot]
api_key = "your-api-key"
base_url = "https://api.moonshot.cn/v1"
```

## Security Considerations

1. **API Key Management** - Never hardcode API keys, use environment variables
2. **YOLO Mode** - Only use `-y` for trusted tasks in controlled environments
3. **Working Directory** - Always set explicit working directories to prevent accidental file access
4. **Command Injection** - Sanitize task prompts when accepting user input
5. **Timeouts** - Always set reasonable timeouts to prevent hanging

## Error Handling

```python
import subprocess

def safe_kimi_call(task: str, **kwargs) -> dict:
    """Safely call Kimi with error handling."""
    cmd = ["kimi", "--print", "--quiet"]
    
    if kwargs.get("work_dir"):
        cmd.extend(["-w", kwargs["work_dir"]])
    if kwargs.get("yolo"):
        cmd.append("-y")
    
    cmd.extend(["--prompt", task])
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=kwargs.get("timeout", 300)
        )
        
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr if result.returncode != 0 else None,
            "exit_code": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Request timed out",
            "exit_code": -1
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "exit_code": -1
        }
```

## Limitations

1. **No Real-Time Streaming** - Subprocess mode waits for completion
2. **Session State** - Each subprocess call is stateless unless using ACP
3. **Approval Required** - Sensitive operations require user approval (unless YOLO mode)
4. **Rate Limits** - Subject to API rate limits

## Troubleshooting

### Kimi Not Found

```bash
# Check installation
which kimi

# If not found, ensure it's in PATH
export PATH="$HOME/.local/bin:$PATH"
```

### API Key Issues

```bash
# Verify API key is set
echo $MOONSHOT_API_KEY

# Test with simple command
kimi --print --quiet "Hello"
```

### Timeout Issues

```bash
# For long-running tasks, increase timeout
kimi --print --quiet --config '{"timeout": 600}' "Long task"
```
