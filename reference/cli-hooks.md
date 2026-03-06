# Hook systems across AI coding CLI tools

**Claude Code and Gemini CLI offer the most mature, production-ready hook systems — both supporting shell command hooks with blocking, filtering, and behavior modification across the full agent lifecycle.** OpenCode takes a fundamentally different approach with a TypeScript/JS plugin architecture that provides even broader event coverage (27+ events) but requires code rather than config. OpenAI Codex CLI lags significantly, offering only a single fire-and-forget notification event, though a full hook system is confirmed "in development."

These four tools represent the leading edge of AI-assisted coding CLIs, and their hook systems reveal starkly different design philosophies: Claude Code and Gemini CLI favor declarative JSON config with shell commands, OpenCode favors programmatic plugins, and Codex CLI has yet to ship a real hook system at all.

---

## The comparative matrix

The table below maps equivalent hook concepts across all four tools, normalizing different naming conventions into functional categories. A ✅ indicates full support with blocking/modification capability; 📡 indicates fire-and-forget observation only; ❌ indicates no support.

| Hook concept | Claude Code | Codex CLI | Gemini CLI | OpenCode |
|:---|:---|:---|:---|:---|
| **Before tool execution** | `PreToolUse` ✅ | ❌ | `BeforeTool` ✅ | `tool.execute.before` ✅ |
| **After tool execution** | `PostToolUse` ✅ | ❌ | `AfterTool` ✅ | `tool.execute.after` 📡 |
| **Tool execution failure** | `PostToolUseFailure` ✅ | ❌ | via `AfterTool` ✅ | ❌ |
| **Before user prompt processed** | `UserPromptSubmit` ✅ | ❌ | `BeforeAgent` ✅ | ❌ |
| **Agent turn complete / stop** | `Stop` ✅ | `notify` (agent-turn-complete) 📡 | `AfterAgent` ✅ | `stop` hook ✅ |
| **Before model/LLM call** | ❌ | ❌ | `BeforeModel` ✅ | ❌ |
| **After model/LLM response** | ❌ | ❌ | `AfterModel` ✅ | ❌ |
| **Tool selection control** | ❌ | ❌ | `BeforeToolSelection` ✅ | ❌ |
| **Permission request** | `PermissionRequest` ✅ | ❌ | ❌ | `permission.asked` 📡 |
| **Session start** | `SessionStart` 📡 | ❌ | `SessionStart` 📡 | `session.created` 📡 |
| **Session end** | `SessionEnd` 📡 | ❌ | `SessionEnd` 📡 | ❌ |
| **Notification/alerts** | `Notification` 📡 | TUI notifications (built-in) | `Notification` 📡 | `tui.toast.show` 📡 |
| **Before context compaction** | `PreCompact` 📡 | ❌ | `PreCompress` 📡 | `experimental.session.compacting` ✅ |
| **Subagent start** | `SubagentStart` 📡 | ❌ | ❌ | ❌ |
| **Subagent stop** | `SubagentStop` ✅ | ❌ | ❌ | ❌ |
| **Setup / initialization** | `Setup` | ❌ | ❌ | ❌ |
| **Config change** | `ConfigChange` 📡 | ❌ | ❌ | ❌ |
| **File edited** | ❌ | ❌ | ❌ | `file.edited` 📡 + config hook |
| **Shell env injection** | `CLAUDE_ENV_FILE` (SessionStart only) | Shell env policy (config) | ❌ | `shell.env` ✅ |
| **System prompt transform** | ❌ | ❌ | via `BeforeModel` ✅ | `experimental.chat.system.transform` ✅ |
| **Custom tool registration** | via MCP | via MCP | via MCP | Plugin `tool` registration ✅ |
| **Instructions loaded** | `InstructionsLoaded` 📡 | ❌ | ❌ | ❌ |
| **Worktree create/remove** | `WorktreeCreate` / `WorktreeRemove` 📡 | ❌ | ❌ | ❌ |
| **Task/teammate events** | `TaskCompleted` / `TeammateIdle` ✅ | ❌ | ❌ | `session.idle` 📡 |

---

## Claude Code has the broadest declarative hook system

Claude Code provides **18 distinct hook events** configured via JSON in `settings.json` at four precedence levels: enterprise managed policy, user (`~/.claude/settings.json`), project (`.claude/settings.json`), and local project (`.claude/settings.local.json`). It stands out for supporting **four handler types** — `command` (shell), `prompt` (sends to a fast LLM like Haiku), `agent` (spawns a multi-turn subagent), and `http` (POSTs JSON to a URL) — whereas the other tools only support shell commands or code.

Configuration follows a clean JSON schema with matcher groups and handler arrays:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Write",
        "hooks": [
          { "type": "command", "command": "./validate.sh", "timeout": 30 }
        ]
      }
    ]
  }
}
```

**Matchers use regex patterns** against tool names (PascalCase: `Bash`, `Write`, `Edit`), notification types, or session sources. Tool argument matching is also possible — `"Bash(npm test*)"` matches specific commands. MCP tools follow the pattern `mcp__<server>__<tool>` and can be matched with patterns like `mcp__memory__.*`.

For flow control, Claude Code uses a **dual mechanism**: exit code 2 blocks execution (stderr becomes the error message), while exit code 0 with JSON stdout enables fine-grained control via `permissionDecision` (`allow`/`deny`/`ask`), `updatedInput` (rewrite tool arguments), and `additionalContext` (inject information). The `async: true` flag runs hooks in the background without blocking, with results delivered on the next conversation turn. Unique features include **subagent hooks** (`SubagentStart`/`SubagentStop`) for multi-agent workflows and the `prompt` handler type that delegates hook logic to an LLM.

---

## Gemini CLI matches depth with unique model-layer hooks

Gemini CLI launched its hook system in **v0.26.0 (January 27, 2026)** with **11 hook events** that cover not just tool execution but also the model/LLM layer — a capability no other tool offers. The `BeforeModel` hook can modify the outgoing LLM request (change the model, temperature, or messages) or return a **synthetic response to skip the LLM call entirely**. `AfterModel` fires on every streaming chunk, enabling real-time redaction or PII filtering. `BeforeToolSelection` controls which tools the model can even consider.

Configuration lives in `settings.json` at project (`.gemini/settings.json`), user (`~/.gemini/settings.json`), or system (`/etc/gemini-cli/settings.json`) levels, plus extension bundles. The schema closely mirrors Claude Code's structure:

```json
{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "write_file|replace",
        "hooks": [
          { "type": "command", "command": "./security.sh", "timeout": 5000 }
        ]
      }
    ]
  }
}
```

Currently only `type: "command"` is supported (no prompt or agent handler types). Gemini CLI adds a `sequential` boolean to control whether hooks within a matcher group run in parallel or series — a feature Claude Code lacks. The `AfterAgent` hook is particularly powerful: setting `decision: "deny"` **rejects the agent's response and forces a retry**, with the reason sent as a new prompt for correction. The `hookSpecificOutput.tailToolCallRequest` field in `AfterTool` can chain tool calls, executing another tool immediately after one completes. Environment variables include `GEMINI_PROJECT_DIR` and, notably, `CLAUDE_PROJECT_DIR` as a **compatibility alias**.

---

## OpenCode takes a programmatic plugin approach

OpenCode diverges from the config-file model entirely. Its primary extensibility mechanism is a **TypeScript/JS plugin system** using the `@opencode-ai/plugin` package. Plugins are loaded from `.opencode/plugins/` (project), `~/.config/opencode/plugins/` (global), or npm packages declared in `opencode.json`. This approach provides **27+ subscribable events** — the broadest event surface of any tool — but requires writing code rather than dropping in a shell script.

```typescript
import type { Plugin } from "@opencode-ai/plugin"
export const MyPlugin: Plugin = async ({ client, directory }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Modify output.args to rewrite tool arguments
      // Throw to block execution
    },
    stop: async (input) => {
      // Re-prompt the agent to continue working
      await client.session.prompt({ path: { id: input.sessionID }, body: { parts: [{ type: "text", text: "Keep going" }] } })
    }
  }
}
```

The plugin context provides direct access to the OpenCode SDK client, shell API, project info, and working directory. **Blocking is done by throwing errors** in `tool.execute.before`, while **modification is done by mutating the `output` object** — a fundamentally different pattern from the JSON-over-stdin/stdout protocol used by the other three tools. OpenCode also offers **experimental JSON config hooks** under `experimental.hook` in `opencode.json` for simpler cases like running a formatter after file edits, including **glob-pattern filtering** (`"*.ts"` runs only for TypeScript files). Unique capabilities include `shell.env` for injecting environment variables into all shell execution and `experimental.chat.system.transform` for modifying the system prompt.

---

## Codex CLI has no real hook system yet

OpenAI Codex CLI's hook capability is **limited to a single `notify` mechanism** that fires an external command when the agent completes a turn. Configured in `~/.codex/config.toml`:

```toml
notify = ["python3", "/path/to/notify.py"]
```

The script receives a JSON argument (via `sys.argv[1]`) containing `type`, `last-assistant-message`, `input-messages`, and `thread-id`. **It cannot block, modify, or intercept any behavior** — it is purely fire-and-forget. Only the `agent-turn-complete` event type is supported. GitHub Issue #2109, with **279+ upvotes**, requests a full event hook system and has been confirmed "in development" by an OpenAI engineer. A comprehensive community PR (#9796) implementing tool hooks, file hooks, and event hooks was **rejected** because OpenAI wants to design the system internally.

Codex CLI compensates with adjacent systems: **execution policy** rules that gate which commands can run (allowed/prompted/blocked), **approval policies** (`untrusted`/`on-request`/`never`) that pause for human approval, and **sandbox modes** that restrict filesystem and network access. These provide pre-execution gating but lack the flexibility, data access, and programmability of true hooks.

---

## Architecture and configuration compared side by side

| Dimension | Claude Code | Codex CLI | Gemini CLI | OpenCode |
|:---|:---|:---|:---|:---|
| **Hook system maturity** | Production | Minimal (1 event) | Production (since v0.26.0) | Production |
| **Total hook events** | 18 | 1 | 11 | 27+ (plugin events) |
| **Config format** | JSON (`settings.json`) | TOML (`config.toml`) | JSON (`settings.json`) | JS/TS plugins + JSON (`opencode.json`) |
| **Handler types** | command, prompt, agent, http | External script only | command only | Plugin functions (JS/TS), experimental shell |
| **Communication protocol** | JSON via stdin→stdout + exit codes | JSON via argv | JSON via stdin→stdout + exit codes | Function arguments + mutations |
| **Can block execution?** | ✅ (exit 2, or JSON decision) | ❌ | ✅ (exit 2, or JSON decision) | ✅ (throw error in plugin) |
| **Can modify tool args?** | ✅ (`updatedInput`) | ❌ | ✅ (`hookSpecificOutput.tool_input`) | ✅ (mutate `output.args`) |
| **Can modify LLM request?** | ❌ | ❌ | ✅ (`BeforeModel`) | ❌ (experimental system prompt only) |
| **Can mock LLM response?** | ❌ | ❌ | ✅ (`llm_response` in BeforeModel) | ❌ |
| **Async/background hooks?** | ✅ (`async: true`) | N/A | ❌ | ❌ |
| **Matcher/filter system** | Regex on tool names | None | Regex on tool names | Glob patterns (config hooks only) |
| **Sequential control** | All parallel | N/A | `sequential` flag | Sequential by load order |
| **LLM-powered hooks?** | ✅ (`type: "prompt"`, `type: "agent"`) | ❌ | ❌ | ❌ |
| **Enterprise controls** | ✅ (managed policy, `allowManagedHooksOnly`) | ❌ | System-level settings | ❌ |
| **Interactive management** | `/hooks` slash command | ❌ | `/hooks` slash command | ❌ |
| **Config precedence levels** | 4 (enterprise → user → project → local) | 1 | 4 (system → user → project → extension) | 4 (global config → project config → global plugins → project plugins) |

---

## Conclusion

The hook landscape across these four tools splits into three tiers. **Gemini CLI uniquely offers model-layer interception** — the ability to rewrite LLM requests, mock responses, filter available tools, and redact streaming output in real time — making it the most powerful choice for teams needing deep control over the AI pipeline itself. **Claude Code leads in operational breadth and enterprise readiness**, with 18 events, four handler types (including LLM-powered prompt and agent hooks that no other tool offers), async background execution, and managed policy controls for organizational deployment. **OpenCode provides the richest programmatic interface** with 27+ events and full SDK access, but requires TypeScript/JS proficiency and lacks the model-layer hooks that Gemini CLI provides. **Codex CLI remains the outlier** — its single notification event is inadequate for serious automation, though its execution policy and approval systems partially compensate.

For teams choosing between these tools based on hook capabilities: Gemini CLI and Claude Code are closest in philosophy and can often substitute for each other (Gemini even provides a `CLAUDE_PROJECT_DIR` compatibility alias). OpenCode suits teams already invested in TypeScript tooling who want maximum event granularity. Codex CLI should only be chosen if hooks are not a priority — though its confirmed-in-development hook system may close the gap in future releases.