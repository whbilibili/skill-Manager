---
name: catdesk-browser
description: "Browser automation via CatPaw Desk CLI. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or automating any browser task."
---

# Browser Automation with CatPaw Desk

> **CRITICAL**: For `*.sankuai.com` URLs, you **MUST** complete the [Meituan Internal Pages](#mandatory-meituan-internal-pages) section **before** running any `browser-action` command. Skipping this is a violation of this skill's instructions.

> **Windows (CMD)**: Replace `~/.catpaw/bin/catdesk` with `%USERPROFILE%\.catpaw\bin\catdesk.cmd` in all commands below.
>
> **Windows (PowerShell)**: The system prompt provides a `catdesk` function definition that wraps the Electron binary and automatically handles PowerShell 5.x quote-stripping. Run the function definition ONCE per shell session (the system prompt provides the exact command), then use `catdesk` identically to macOS/Linux:
>
> ```powershell
> # After running the function definition from the system prompt:
> catdesk browser-action '{"action":"navigate","url":"https://example.com"}'
>
> # Values with spaces work correctly:
> catdesk browser-action '{"action":"fill","selector":"@e1","value":"Jane Doe"}'
>
> # Batch array:
> catdesk browser-action '[{"action":"click","selector":"@e1"},{"action":"snapshot"}]'
> ```
>
> **Rules**:
> - Always use **single quotes** `'...'` around the JSON string (not double quotes)
> - The `catdesk` function automatically escapes `"` for PowerShell 5.x — no manual escaping needed
> - For nested `"` in JS expressions (e.g. `evaluate`), use `''` (two single quotes) to embed a literal single quote, or use template strings to avoid quotes entirely

## MANDATORY: Meituan Internal Pages

For `*.sankuai.com` URLs, **STOP — do NOT run any `browser-action` command yet**. You MUST follow these steps first:

1. **Pick a keyword**: `x.sankuai.com`→`大象`, `km.`→`学城`, `oa.`→`oa`, `ones.`/MEP→`ones`, `bi.`/魔数→`魔数`, 会议室→`会议`, otherwise use the subdomain or task keyword (prefer Chinese).
2. **Use the Read file tool** to read the `catpaw-skill-installer` SKILL.md (try `~/.catpaw/skills/skills-market/catpaw-skill-installer/SKILL.md` first, then `~/.catpaw/skills/catpaw-skill-installer/SKILL.md`). Follow its instructions to run `find-skills` with the keyword. Do NOT guess the binary path.
3. **If any results returned** → Show ALL results to the user in the installer's table format and ask whether to install. **Stop and wait — do NOT run browser-action.** Do NOT filter results by relevance — that is the user's decision, not yours. If the user wants to install, follow the installer skill's instructions, then use that skill. If the user declines or zero results → proceed with browser-action below.

> Skip only if the user explicitly wants browser automation or the relevant skill is already installed.

## Core Workflow

> If the target URL is `*.sankuai.com`, complete the [MANDATORY: Meituan Internal Pages](#mandatory-meituan-internal-pages) section first.

Every browser automation follows this pattern:

1. **Navigate**: `{"action":"navigate","url":"..."}`
2. **Snapshot**: `{"action":"snapshot","interactive":true}` (get element refs like `@e1`, `@e2`)
3. **Interact**: Use refs to click, fill, select
4. **Re-snapshot**: After navigation or DOM changes, get fresh refs

> Prefer `snapshot` over `screenshot` to inspect page state — snapshot returns a lightweight accessibility tree (text) and is more token-efficient. Use `screenshot` only when you need visual information that snapshot cannot provide (see [Annotated Screenshots](#annotated-screenshots-vision-mode)).

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://example.com/form"}'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
# Output: @e1 [input type="email"], @e2 [input type="password"], @e3 [button] "Submit"

~/.catpaw/bin/catdesk browser-action '[{"action":"fill","selector":"@e1","value":"user@example.com"},{"action":"fill","selector":"@e2","value":"password123"},{"action":"click","selector":"@e3"},{"action":"waitforloadstate","state":"networkidle"}]'

~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
```

## Batch Execution

Pass a JSON array to run multiple commands sequentially. Stops on first failure.

```bash
~/.catpaw/bin/catdesk browser-action '[{"action":"fill","selector":"@e1","value":"text"},{"action":"keyboard","keys":"Enter"},{"action":"wait","timeout":2000}]'
```

**When to batch**: `fill + keyboard + wait`, `click + fill + keyboard` — any sequence where you don't need intermediate output.

**When NOT to batch**: `snapshot` (you need the output), `navigate` (may fail/redirect), `click` that opens new content (need fresh refs).

## Essential Commands

```bash
# Navigation
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"<url>","waitUntil":"networkidle"}'
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"<url>","headers":{"X-Auth":"token","X-Custom":"value"}}'
~/.catpaw/bin/catdesk browser-action '{"action":"back"}'
~/.catpaw/bin/catdesk browser-action '{"action":"forward"}'
~/.catpaw/bin/catdesk browser-action '{"action":"reload"}'

# Snapshot
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true,"selector":"#main"}'

# Interaction (use @refs from snapshot)
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e1"}'
~/.catpaw/bin/catdesk browser-action '{"action":"fill","selector":"@e2","value":"text"}'
~/.catpaw/bin/catdesk browser-action '{"action":"type","selector":"@e2","text":"text"}'
~/.catpaw/bin/catdesk browser-action '{"action":"select","selector":"@e1","values":"option"}'
~/.catpaw/bin/catdesk browser-action '{"action":"check","selector":"@e1"}'
~/.catpaw/bin/catdesk browser-action '{"action":"press","key":"Enter"}'
~/.catpaw/bin/catdesk browser-action '{"action":"keyboard","keys":"Control+a"}'
~/.catpaw/bin/catdesk browser-action '{"action":"scroll","direction":"down","amount":500}'
~/.catpaw/bin/catdesk browser-action '{"action":"upload","selector":"@e1","files":"./file.pdf"}'
~/.catpaw/bin/catdesk browser-action '{"action":"upload","selector":"@e1","files":["./a.pdf","./b.png"]}'

# Get information
~/.catpaw/bin/catdesk browser-action '{"action":"url"}'
~/.catpaw/bin/catdesk browser-action '{"action":"title"}'
~/.catpaw/bin/catdesk browser-action '{"action":"content","selector":"@e1"}'

# Wait
~/.catpaw/bin/catdesk browser-action '{"action":"wait","timeout":2000}'
~/.catpaw/bin/catdesk browser-action '{"action":"wait","selector":"@e1"}'
~/.catpaw/bin/catdesk browser-action '{"action":"waitforloadstate","state":"networkidle"}'
~/.catpaw/bin/catdesk browser-action '{"action":"waitforurl","url":"**/dashboard"}'

# Tabs
~/.catpaw/bin/catdesk browser-action '{"action":"tab_new","url":"https://example.com"}'
~/.catpaw/bin/catdesk browser-action '{"action":"tab_list"}'
~/.catpaw/bin/catdesk browser-action '{"action":"tab_switch","index":0}'
~/.catpaw/bin/catdesk browser-action '{"action":"tab_close","index":0}'

# Network & Headers
~/.catpaw/bin/catdesk browser-action '{"action":"headers","headers":{"X-Auth":"token123"}}'

# Capture
~/.catpaw/bin/catdesk browser-action '{"action":"screenshot"}'
~/.catpaw/bin/catdesk browser-action '{"action":"screenshot","fullPage":true}'
~/.catpaw/bin/catdesk browser-action '{"action":"screenshot","annotate":true}'
~/.catpaw/bin/catdesk browser-action '{"action":"pdf","path":"output.pdf"}'
```

## Common Patterns

### Form Submission

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://example.com/signup"}'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
~/.catpaw/bin/catdesk browser-action '[{"action":"fill","selector":"@e1","value":"Jane Doe"},{"action":"fill","selector":"@e2","value":"jane@example.com"},{"action":"select","selector":"@e3","values":"California"},{"action":"check","selector":"@e4"},{"action":"click","selector":"@e5"},{"action":"waitforloadstate","state":"networkidle"}]'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
```

### File Upload

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://example.com/upload"}'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
# Find the file input: @e1 [input type="file"]
~/.catpaw/bin/catdesk browser-action '{"action":"upload","selector":"@e1","files":"./report.pdf"}'
# Multiple files
~/.catpaw/bin/catdesk browser-action '{"action":"upload","selector":"@e1","files":["./photo1.png","./photo2.jpg"]}'
```

`selector` must point to an `<input type="file">` element. `files` accepts a single path or an array of paths.

### Data Extraction

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://example.com/products"}'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
~/.catpaw/bin/catdesk browser-action '{"action":"content","selector":"@e5"}'
```

### Authentication with State Persistence

```bash
# Login once and save state
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://app.example.com/login"}'
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
~/.catpaw/bin/catdesk browser-action '[{"action":"fill","selector":"@e1","value":"user@example.com"},{"action":"fill","selector":"@e2","value":"password123"},{"action":"click","selector":"@e3"}]'
~/.catpaw/bin/catdesk browser-action '{"action":"waitforurl","url":"**/dashboard"}'
~/.catpaw/bin/catdesk browser-action '{"action":"state_save","path":"auth.json"}'

# Reuse in future sessions
~/.catpaw/bin/catdesk browser-action '{"action":"state_load","path":"auth.json"}'
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://app.example.com/dashboard"}'
```

### Semantic Locators (when refs unavailable)

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"getbyrole","role":"button","name":"Submit","subaction":"click"}'
~/.catpaw/bin/catdesk browser-action '{"action":"getbylabel","label":"Email","subaction":"fill","value":"user@test.com"}'
~/.catpaw/bin/catdesk browser-action '{"action":"getbytext","text":"Sign In","subaction":"click"}'
~/.catpaw/bin/catdesk browser-action '{"action":"getbyplaceholder","placeholder":"Search","subaction":"fill","value":"query"}'
~/.catpaw/bin/catdesk browser-action '{"action":"getbytestid","testId":"submit-btn","subaction":"click"}'
```

`subaction` can be: `"click"`, `"fill"`, `"hover"`, `"check"`

### Annotated Screenshots (Vision Mode)

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"screenshot","annotate":true}'
# Output includes the image path and a legend:
#   [1] @e1 button "Submit"
#   [2] @e2 link "Home"
#   [3] @e3 textbox "Email"
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e2"}'
```

Use annotated screenshots when the page has unlabeled icon buttons or you need spatial reasoning about element positions.

### Diff (Verifying Changes)

```bash
# Snapshot -> action -> diff
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e2"}'
~/.catpaw/bin/catdesk browser-action '{"action":"diff_snapshot"}'

# Visual regression
~/.catpaw/bin/catdesk browser-action '{"action":"diff_screenshot","baseline":"before.png"}'

# Compare two pages
~/.catpaw/bin/catdesk browser-action '{"action":"diff_url","url1":"https://staging.example.com","url2":"https://prod.example.com","screenshot":true}'
```

### JavaScript Evaluation

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"evaluate","script":"document.title"}'
~/.catpaw/bin/catdesk browser-action '{"action":"evaluate","script":"document.querySelectorAll(\"img\").length"}'
```

**Note**: JSON escaping can corrupt complex JavaScript. Use simpler expressions or chain multiple evaluate calls.

## Ref Lifecycle (Important)

Refs (`@e1`, `@e2`, etc.) are invalidated when the page changes. Always re-snapshot after:

- Clicking links or buttons that navigate
- Form submissions
- Dynamic content loading (dropdowns, modals)

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e5"}'  # Navigates
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'  # MUST re-snapshot
```

## Wait Strategies

```bash
# Wait for network idle (best for slow pages)
~/.catpaw/bin/catdesk browser-action '{"action":"waitforloadstate","state":"networkidle"}'

# Wait for a specific element
~/.catpaw/bin/catdesk browser-action '{"action":"wait","selector":"@e1"}'

# Wait for URL pattern (useful after redirects)
~/.catpaw/bin/catdesk browser-action '{"action":"waitforurl","url":"**/dashboard"}'

# Wait for JavaScript condition
~/.catpaw/bin/catdesk browser-action '{"action":"waitforfunction","expression":"document.readyState === \"complete\""}'

# Fixed duration (milliseconds)
~/.catpaw/bin/catdesk browser-action '{"action":"wait","timeout":5000}'
```

## Downloads

```bash
# Click element to trigger download
~/.catpaw/bin/catdesk browser-action '{"action":"download","selector":"@e1","path":"./file.pdf"}'

# Wait for download to complete
~/.catpaw/bin/catdesk browser-action '{"action":"waitfordownload","path":"./output.zip","timeout":30000}'
```

## Performance Profiling

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"profiler_start"}'
~/.catpaw/bin/catdesk browser-action '{"action":"navigate","url":"https://example.com"}'
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e1"}'
~/.catpaw/bin/catdesk browser-action '{"action":"profiler_stop","path":"./trace.json"}'
```

Open trace.json in Chrome DevTools (Performance panel) or [Perfetto UI](https://ui.perfetto.dev/) for analysis.

## Viewport & Device Emulation

```bash
~/.catpaw/bin/catdesk browser-action '{"action":"viewport","width":1920,"height":1080}'
~/.catpaw/bin/catdesk browser-action '{"action":"viewport","width":1920,"height":1080,"deviceScaleFactor":2}'
~/.catpaw/bin/catdesk browser-action '{"action":"device","device":"iPhone 14"}'
~/.catpaw/bin/catdesk browser-action '{"action":"emulatemedia","colorScheme":"dark"}'
```

## Actions Reference

### Navigation
- `navigate` — `{url, waitUntil?, headers?}` Navigate to URL. Optional `headers` injects custom HTTP headers (origin-scoped) into all subsequent requests to that origin.
- `back` / `forward` / `reload` — Browser history navigation

### Snapshot & Screenshot
- `snapshot` — `{interactive?, compact?, maxDepth?, selector?}` Get accessibility tree
- `screenshot` — `{fullPage?, selector?, annotate?}` Take screenshot
- `pdf` — `{path, format?}` Export as PDF

### Interaction
- `click` — `{selector, button?}` Click element
- `dblclick` — `{selector}` Double click
- `hover` — `{selector}` Hover
- `type` — `{selector, text, clear?}` Type character by character
- `fill` — `{selector, value}` Fill input (auto-focuses)
- `press` — `{key, selector?}` Press key
- `check` / `uncheck` — `{selector}` Toggle checkbox
- `select` — `{selector, values}` Select dropdown option
- `upload` — `{selector, files}` Upload files
- `drag` — `{source, target}` Drag and drop

### Keyboard & Scroll
- `keyboard` — `{keys, subaction?}` Press keys
- `scroll` — `{selector?, direction?, amount?}` Scroll
- `scrollintoview` — `{selector}` Scroll element into view

### Wait
- `wait` — `{timeout?}` or `{selector, state?}` Wait for element or duration
- `waitforurl` — `{url, timeout?}` Wait for URL pattern
- `waitforloadstate` — `{state}` Wait for `"networkidle"` or `"load"`
- `waitforfunction` — `{expression, timeout?}` Wait for JS expression

### Info
- `url` / `title` — Get current URL or title
- `content` — `{selector?}` Get text content
- `gettext` / `innerhtml` / `innertext` — `{selector}` Get element content
- `getattribute` — `{selector, attribute}` Get attribute
- `isvisible` / `isenabled` / `ischecked` — `{selector}` Check element state

### Tabs (max 4 per session)
- `tab_new` — `{url?}` Open new tab (fails at limit — close a tab or use `navigate` to reuse one)
- `tab_list` — List all tabs (returns `openTabs`, `maxTabs`)
- `tab_switch` — `{index}` Switch tab
- `tab_close` — `{index?}` Close tab

### Semantic Locators
- `getbyrole` — `{role, name?, subaction, value?}`
- `getbytext` — `{text, subaction}`
- `getbylabel` — `{label, subaction, value?}`
- `getbyplaceholder` — `{placeholder, subaction, value?}`
- `getbytestid` — `{testId, subaction, value?}`

### Storage & Network
- `cookies_get` / `cookies_set` / `cookies_clear` — Cookie management
- `storage_get` / `storage_set` / `storage_clear` — localStorage/sessionStorage
- `headers` — `{headers}` Set extra HTTP headers for all subsequent requests (global)
- `route` / `unroute` — Request interception
- `offline` — `{offline}` Toggle offline mode

### State & Diff
- `state_save` / `state_load` / `state_list` / `state_clear` — State persistence
- `diff_snapshot` / `diff_screenshot` / `diff_url` — Page comparison

### Advanced
- `evaluate` — `{script, args?}` Execute JavaScript
- `frame` / `mainframe` — Switch iframe context
- `dialog` — `{response, promptText?}` Handle alerts
- `download` / `waitfordownload` — File downloads
- `profiler_start` / `profiler_stop` — Performance profiling
- `viewport` / `device` / `emulatemedia` — Viewport and media emulation

## CatPaw Desk vs CLI Version

| Feature | CLI (`agent-browser`) | CatPaw Desk (Electron) |
|---------|----------------------|------------------------|
| `launch`/`close` | Required | No-op (browser always running) |
| `recording_*` | Records WebM video | No-op (not supported) |
| Session isolation | `--session` flag | Automatic via `CATPAW_CONVERSATION_ID` |
| Browser visibility | `--headed` flag | Always visible (WebContentsView) |

## Multi-Tab Handling (Important)

**Tab limit: maximum 4 tabs per session.** Tab-related commands return `openTabs` and `maxTabs` in their response. When the limit is reached, `tab_new` will fail with the current tab list — close a tab you no longer need or use `navigate` on an existing tab instead.

Clicking links may open a **new tab** (e.g. `target="_blank"`). When this happens the command response includes a `_tabChanged` notice. Similarly, `snapshot` responses include a `_tabContext` field when multiple tabs are open.

### When to keep tabs open vs. close them

- **Keep a tab open** if you still need it — e.g. switching between two pages to compare data, or returning to a search results page after reading a result.
- **Close a tab** when you are confident you will not need it again — e.g. you have finished extracting all needed information from that page, or it was opened automatically (e.g. `target="_blank"`) and you are done reading it.
- **When you no longer need any browser tabs** (e.g. browser part of the task is complete), close all remaining tabs so they don't occupy resources.
- **Do NOT close and immediately re-open tabs for the same URL** — that wastes operations. Use `tab_switch` to go back to an existing tab instead.

### Close-and-Return Pattern (browse search results one by one)

```bash
# 1. On search results page, click a result link
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e3"}'
# Response may include: _tabChanged { notice: "A new tab was opened...", hint: "use tab_close to return" }

# 2. Read the new tab content
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'

# 3. Done with this result — close current tab to return to search results
~/.catpaw/bin/catdesk browser-action '{"action":"tab_close"}'

# 4. Back on search results page — re-snapshot and click next result
~/.catpaw/bin/catdesk browser-action '{"action":"snapshot","interactive":true}'
~/.catpaw/bin/catdesk browser-action '{"action":"click","selector":"@e5"}'
```

### Rules

- To return to a previous page after a new tab opens: **use `tab_close`** (closes current tab, auto-returns to previous tab).
- Do **NOT** use `navigate` or `back` to return — that navigates within the current tab and leaves extra tabs accumulating.
- Use `tab_list` to see all open tabs and `tab_switch` to jump between them.
- Prefer `navigate` on the current tab over `tab_new` when you don't need to preserve the current page.

## Tips

- Prefer `snapshot` over `screenshot` to check page state — it is text-based and more token-efficient.
- Use `screenshot` for visual verification — unlabeled icon buttons, layout/styling checks, canvas/chart content, or spatial reasoning about element positions.
- **Always prefer batch** for 2+ sequential interactions after a snapshot.
- **`fill` auto-focuses** the target element. Skip `click` if the element is already an input.
- Use `interactive:true` in snapshot to reduce output.
- Refs (`@e1..`) are invalidated after navigation. Always re-snapshot.

## Error Handling

On failure the CLI returns JSON with `"success": false` and an `"error"` message. Common issues:

- Element not found → re-snapshot with `interactive:true` to get fresh refs.
- Timeout → increase `wait` timeout or check if the page loaded correctly.
- Element not visible → use `scrollintoview` first.
- Element disabled → check if a prerequisite action is needed.