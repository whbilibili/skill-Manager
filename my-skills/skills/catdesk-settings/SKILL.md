---
name: catdesk-settings
description: "Manage CatPaw Desk application settings, custom commands, MCP server configurations, app lifecycle, application logs, session information, and authentication via CLI, plus show native system notifications. Use when the user asks to: change preferences/toggle features/adjust fonts/configure shortcuts/modify any app setting, switch sandbox mode (e.g. 'full access'/'完全访问'/'allow all'/'不要限制'), allow or stop confirming file deletions (e.g. '允许直接删除'/'不要再问我删除'/'别再确认删除了'/'stop asking to confirm delete' — these mean switch to full-access sandbox mode), create/edit/delete custom commands (slash commands), add/remove/enable/disable MCP servers, show a system notification, check app version, check for updates, update the app, restart the app, view/read application logs, check main/renderer/agent logs, list or read conversation logs, list sessions, get current session, get conversationId, check session status, check safe house status (e.g. '是否开启安全屋'/'安全屋模式'/'safe house'/'isSafeHouse'), enable/disable prevent sleep (e.g. '防止休眠'/'阻止休眠'/'阻止系统休眠'/'prevent system sleep'/'keep awake'/'不要让电脑休眠'), get login info (e.g. '登录信息'/'当前用户'/'who am i'), get SSO token (e.g. '获取token'/'get access token'), or exchange token for another app (e.g. 'token交换'/'exchange token')."
---

# CatPaw Desk Settings, Configuration, Sessions & Logs Manager

> **Windows (CMD)**: Replace `~/.catpaw/bin/catdesk` with `%USERPROFILE%\.catpaw\bin\catdesk.cmd` in all commands below.
>
> **Windows (PowerShell)**: `catdesk.cmd` is a CMD batch script. PowerShell 5.x strips quotes from JSON arguments when calling `.cmd` files. **Use `$env:USERPROFILE` and store JSON in a variable with escaped quotes:**
>
> ```powershell
> & "$env:USERPROFILE\.catpaw\bin\catdesk.cmd" settings list
> # For commands with JSON args:
> $json = '{\"key\":\"value\"}'; & "$env:USERPROFILE\.catpaw\bin\catdesk.cmd" settings set $json
> ```

Manage CatPaw Desk settings, custom commands, MCP server configurations, app lifecycle, session information, application logs, and authentication via CLI.

## How It Works

CatPaw Desk exposes configuration through a CLI interface. The Agent uses `terminal_execute` to run CLI commands. All output is JSON.

**Important**: Do NOT hardcode setting names — always run `settings list` first to discover available settings.

---

## 1. Settings — App Preferences

All commands: `~/.catpaw/bin/catdesk settings <action> [options]`

### List all settings (always do this first)

```bash
~/.catpaw/bin/catdesk settings list
```

Returns a JSON array. Each element:

```json
{
  "key": "sandboxMode",
  "type": "enum",
  "current": "workspace-write",
  "default": "workspace-write",
  "description": "Agent 文件系统访问权限",
  "category": "sandbox",
  "values": ["workspace-write", "readonly", "full-access"]
}
```

Fields: `key`, `type` (boolean/string/number/enum), `current`, `default`, `description`, `category`. Optional: `values` (enum), `range` (number `{min,max}`), `platform`.

### Get a single setting

```bash
~/.catpaw/bin/catdesk settings get --key <settingKey>
```

### Set a single setting

```bash
~/.catpaw/bin/catdesk settings set --key <settingKey> --value <newValue>
```

### Batch set multiple settings

```bash
~/.catpaw/bin/catdesk settings set --json '{"key1":"value1","key2":"value2"}'
```

### Reset a setting / all settings

```bash
~/.catpaw/bin/catdesk settings reset --key <settingKey>
~/.catpaw/bin/catdesk settings reset --all
```

### Settings Workflow

1. **Discover**: Run `settings list` — parse the JSON to see all keys, types, current values, and constraints.
2. **Plan**: Match the user's request to the appropriate setting key(s).
3. **Confirm**: Tell the user what you're about to change (old → new).
4. **Execute**: Run `settings set` (single or batch) or `settings reset`.
5. **Verify**: Parse the JSON output and check `"success": true`.

---

## 2. Commands — Custom Slash Commands

Manages `~/.catpaw/commands/*.md` files. These appear as slash commands in the chat input and are injected as system prompts.

All commands: `~/.catpaw/bin/catdesk commands <action> [options]`

### List all commands

```bash
~/.catpaw/bin/catdesk commands list
```

Returns: `[{"name":"my-command","id":"my-command"}, ...]`

### Get a command's content

```bash
~/.catpaw/bin/catdesk commands get --name <commandName>
```

Returns: `{"name":"...","content":"# markdown content..."}`

### Create a command

```bash
~/.catpaw/bin/catdesk commands create --name <commandName> [--content "# My Command\n\nInstructions..."]
```

If `--content` is omitted, creates a file with a default heading.

### Update a command

```bash
~/.catpaw/bin/catdesk commands update --name <commandName> --content "new markdown content"
```

### Delete a command

```bash
~/.catpaw/bin/catdesk commands delete --name <commandName>
```

### Commands Workflow

1. Run `commands list` to discover existing commands.
2. To create: `commands create --name <name> --content "<markdown>"`.
3. To update: `commands update --name <name> --content "<markdown>"`.
4. To delete: `commands delete --name <name>`.

---

## 3. MCP — MCP Server Configurations

Manages `~/.catpaw/mcp/servers.json`. Changes take effect starting from the next conversation (no need to create a new session — continuing an existing session also picks up the changes).

All commands: `~/.catpaw/bin/catdesk mcp <action> [options]`

### List all MCP servers

```bash
~/.catpaw/bin/catdesk mcp list
```

Returns a JSON array:

```json
[
  {
    "name": "my-server",
    "source": "manual",
    "type": "stdio",
    "disabled": false,
    "command": "npx",
    "args": ["-y", "some-mcp-server"]
  }
]
```

### Get a single MCP server

```bash
~/.catpaw/bin/catdesk mcp get --name <serverName>
```

### Add or update an MCP server

```bash
~/.catpaw/bin/catdesk mcp add --name <serverName> --json '<configJson>'
```

Three transport types supported:

**Stdio** (local process):
```bash
~/.catpaw/bin/catdesk mcp add --name my-tool --json '{"command":"npx","args":["-y","some-mcp"],"env":{"API_KEY":"xxx"}}'
```

**SSE** (Server-Sent Events):
```bash
~/.catpaw/bin/catdesk mcp add --name my-sse --json '{"type":"sse","url":"http://localhost:3000/sse"}'
```

**Streamable HTTP**:
```bash
~/.catpaw/bin/catdesk mcp add --name my-http --json '{"type":"streamable-http","url":"http://example.com/mcp","headers":{"Authorization":"Bearer xxx"}}'
```

Optional fields:
- `"description"` — human-readable description.
- `"timeout"` — request timeout in milliseconds (default: 60000, i.e. 60s). Example: `"timeout": 3600000` for 1 hour.

### Remove an MCP server

```bash
~/.catpaw/bin/catdesk mcp remove --name <serverName>
```

### Enable/disable an MCP server

```bash
~/.catpaw/bin/catdesk mcp toggle --name <serverName> --enable
~/.catpaw/bin/catdesk mcp toggle --name <serverName> --disable
```

### MCP Workflow

1. Run `mcp list` to see current servers.
2. To add: `mcp add --name <name> --json '<config>'`.
3. To toggle: `mcp toggle --name <name> --disable` or `--enable`.
4. To remove: `mcp remove --name <name>`.
5. New/changed MCP servers take effect starting from the **next conversation** (no need to create a new session).
6. If `mcp add` returns `"updated": true`, the server was already configured. The old config may still be active in the current session — it will be refreshed on the next conversation.

---

## 4. System Notification

Show a native OS notification to alert the user.

```bash
~/.catpaw/bin/catdesk notify -m "message" [-t "title"] [--type info|warning|error]
```

---

## 5. App Lifecycle — Version & Update

Manage app version and updates programmatically.

All commands: `~/.catpaw/bin/catdesk app <sub-command>`

### Show current version

```bash
~/.catpaw/bin/catdesk app version
```

Prints: `CatDesk <version> (<platform>/<arch>)` and Electron/Node versions.

### Check for updates

```bash
~/.catpaw/bin/catdesk app check-update
```

Reports whether a newer version is available. **If an update is found, the download starts automatically.** A "更新" button will appear in the sidebar header when ready — no extra CLI command needed.

### Download and install update

```bash
~/.catpaw/bin/catdesk app update
```

Checks for updates, downloads the new version if available, and **automatically restarts** the app to install it. If already up to date, prints a message and exits.

**Note**: `update` will cause the app to quit and relaunch. The CLI client handles this gracefully — the command exits with code 0 after the restart is initiated. Before calling `app update`, use `todo_write` to mark ALL relevant TODO items as `completed`, since the restart terminates the current conversation stream.

---

## 6. Sessions — Session & Conversation Information

Query session data to obtain `conversationId` and session status. Essential for debugging with the `log` command.

All commands: `~/.catpaw/bin/catdesk session <sub-command>`

### Get current session

```bash
~/.catpaw/bin/catdesk session current
```

Returns the currently active session:

```json
{
  "sessionId": "abc-123",
  "conversationId": "conv_xyz789",
  "title": "Fix login bug",
  "status": "running",
  "projectPath": "/Users/me/project",
  "timestamp": 1710590400000,
  "isCurrent": true,
  "isSafeHouse": false
}
```

### List all sessions

```bash
~/.catpaw/bin/catdesk session list
```

Returns a JSON array of all active (non-archived) sessions, sorted by timestamp (newest first). Each entry includes `sessionId`, `conversationId`, `title`, `status`, `projectPath`, `timestamp`, `isCurrent`, and `isSafeHouse`.

### Check safe house status (current session)

To check whether the **current session** has safe house mode enabled, use `session current` and read the `isSafeHouse` field:

```bash
~/.catpaw/bin/catdesk session current
# → look at the "isSafeHouse" field in the returned JSON
```

**Important**: Do NOT use `settings get --key defaultEnableSafeHouse` to check safe house status. That setting only controls whether **new** sessions default to safe house mode — it does NOT reflect the current session's actual state. Always use `session current` → `isSafeHouse` for the per-session safe house status.

---

## 7. Logs — Application Log Access & Debugging

Read application logs for debugging. Logs are split by concern:

- **main.log** — Main process (IPC, lifecycle, window management, electron-log catch-all)
- **renderer.log** — Renderer process (UI errors, React warnings)
- **agent.log** — Agent stream lifecycle (query/stop/resume, events, tool calls, errors)
- **conversations/{id}.log** — Per-conversation event logs (full lifecycle of a single conversation)

All commands: `~/.catpaw/bin/catdesk log <sub-command> [options]`

### Show main process log

```bash
~/.catpaw/bin/catdesk log main
~/.catpaw/bin/catdesk log main -n 200    # last 200 lines (default: 100)
```

### Show renderer process log

```bash
~/.catpaw/bin/catdesk log renderer
~/.catpaw/bin/catdesk log renderer -n 50
```

### Show agent log

```bash
~/.catpaw/bin/catdesk log agent
~/.catpaw/bin/catdesk log agent -n 200
```

### List available conversation logs

```bash
~/.catpaw/bin/catdesk log list
```

Returns a JSON array sorted by modification time (newest first):

```json
[
  { "id": "conv_abc123", "size": 4096, "mtime": "2026-03-16T10:30:00.000Z" },
  { "id": "conv_def456", "size": 2048, "mtime": "2026-03-16T09:15:00.000Z" }
]
```

### Show a specific conversation log

```bash
~/.catpaw/bin/catdesk log conversation --id <conversationId>
~/.catpaw/bin/catdesk log conversation --id <conversationId> -n 50   # last 50 lines
```

Omit `-n` to get the full conversation log.

### Debugging Workflow

1. **Get conversationId**: `session current` — get the current session's `conversationId`.
2. **Quick triage**: `log agent -n 50` — check for recent errors or unexpected events.
3. **Find other conversations**: `session list` or `log list` — find the conversation ID of a specific session.
4. **Deep dive**: `log conversation --id <conversationId>` — read the full event stream of that conversation.
5. **Cross-reference**: `log main -n 200` — check for IPC or service-level errors around the same timestamp.
6. **Renderer issues**: `log renderer` — check for UI/React errors.

### Log File Locations

All logs are stored in `~/.catpaw/logs/`:

```
~/.catpaw/logs/
├── main.log              # electron-log, 10 MB rotation
├── renderer.log          # Renderer warn/error, 10 MB rotation (shared electron-log transport)
├── agent.log             # Agent lifecycle, 5 MB rotation
└── conversations/        # Per-conversation logs (auto-cleaned: max 50 files / 7 days)
    ├── {conversationId}.log
    └── ...
```

---

## 8. Auth — Authentication & Token Operations

Query login status, obtain SSO access tokens, and exchange tokens for third-party application access. Useful for skills that need to call Meituan internal APIs on behalf of the current user.

All commands: `~/.catpaw/bin/catdesk auth <sub-command> [options]`

### Get login info

```bash
~/.catpaw/bin/catdesk auth info
```

Returns the current login status and user information:

```json
{
  "loggedIn": true,
  "mis": "zhangsan",
  "name": "张三",
  "env": "prod",
  "clientId": "catdesk-xxx"
}
```

If not logged in, returns `{"loggedIn": false}`.

### Get SSO access token

```bash
~/.catpaw/bin/catdesk auth token
```

Returns a valid SSO access token. If the current token is nearing expiry, it is automatically refreshed before returning.

```json
{
  "accessToken": "eyJhbGciOiJSUzI1NiIs...",
  "expiresIn": 3500
}
```

`expiresIn` is the approximate remaining lifetime in seconds.

### Exchange token for a target application

```bash
~/.catpaw/bin/catdesk auth exchange --target-client-id <clientId>
```

Exchanges the current SSO token for a token scoped to the target application (identified by its SSO client ID). CatDesk acts as the authorized application — the exchanged token allows the caller to access the target application's APIs on behalf of the logged-in user.

```json
{
  "accessToken": "eyJhbGciOiJSUzI1NiIs...",
  "expiresIn": 3600,
  "targetClientId": "target-app-client-id"
}
```

### Auth Workflow

1. **Check login**: `auth info` — verify user is logged in and get MIS / name.
2. **Get token**: `auth token` — obtain a valid SSO access token for direct API calls.
3. **Cross-app access**: `auth exchange --target-client-id <id>` — exchange for a token scoped to the target application.

---

## Error Handling

On failure the CLI exits with code 1 and writes to stderr: `Error: <message>`. Common errors:
- Unknown key/name → run the corresponding `list` command to discover valid values.
- Invalid value → check `type`, `values` (enum), `range` (number) from the list output.
- MCP server not found → verify the name with `mcp list`.

## Notes

- **Settings** take effect immediately in the GUI (no restart required). The running UI auto-syncs via IPC broadcast.
- Some settings trigger side effects (e.g. `sandboxMode` updates all running agents, `openAtLogin` syncs with OS).
- **Sandbox mode controls file deletion confirmation**: In `full-access` mode, the Agent can delete files without asking. In other modes (`workspace-write`, `readonly`), every deletion requires user confirmation. So when users say things like "允许直接删除文件"/"不要再问我删除"/"stop asking to confirm delete", set `sandboxMode` to `full-access`.
- **Commands** are `.md` files in `~/.catpaw/commands/`. They show as slash commands in chat and get injected as system prompts.
- **MCP servers** persist in `~/.catpaw/mcp/servers.json`. Config changes are picked up starting from the next conversation (no need to create a new session).
- **Logs** are stored in `~/.catpaw/logs/`. Conversation logs are auto-cleaned on app startup (keeps max 50 files or 7 days). Main/renderer/agent logs have size-based rotation.
- **Sessions** are the primary way to obtain `conversationId` for log queries. Use `session current` to get the current conversation's ID.