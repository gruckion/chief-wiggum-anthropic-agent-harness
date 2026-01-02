# Marathon Ralph Issues

## Issue 1: Linear MCP OAuth Authentication Requirement

**Status:** FIXED
**Priority:** Critical
**Component:** agents/setup.md, plugin configuration

### Description

The marathon-ralph plugin is configured to use the official Linear MCP server at `https://mcp.linear.app/mcp` which requires OAuth 2.1 authentication. This requires manual user intervention to complete the OAuth flow via browser.

However, the user has a `LINEAR_API_KEY` available in their `.env` file.

### Root Cause

The plan_v3.md specifies using:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

This official Linear MCP requires OAuth authentication, not API key auth.

### Solution

Use the third-party `linear-mcp-server` npm package which supports API key authentication via environment variable.

**Option A: Plugin-level .mcp.json (Recommended)**

Create `marathon-ralph/.mcp.json`:

```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "linear-mcp-server"],
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}"
      }
    }
  }
}
```

**Option B: Update setup-agent**

Modify `agents/setup.md` to:

1. Check for `LINEAR_API_KEY` in environment
2. Configure the linear-mcp-server via CLI if not already set up
3. Use `mcp__linear__*` tools with API key auth

### Files to Modify

1. Create `marathon-ralph/.mcp.json` - Configure Linear MCP with API key auth
2. Update `marathon-ralph/agents/setup.md` - Check for LINEAR_API_KEY env var, handle API key auth
3. Update `marathon-ralph/README.md` - Document the LINEAR_API_KEY requirement

### References

- [linear-mcp-server on GitHub](https://github.com/jerhadf/linear-mcp-server)
- [Linear MCP Docs](https://linear.app/docs/mcp)
- Plan v3: Lines 30-44 (Prerequisites section)

---

## Issue 2: MCP Tool Names May Differ

**Status:** FIXED (using @tacticlaunch/mcp-linear which has documented tools)
**Priority:** Medium
**Component:** All agents using Linear MCP tools

### Description

The plan_v3.md references tools like `mcp__linear__get_teams`, `mcp__linear__create_project`, etc. However, the actual tool names from the `linear-mcp-server` package may be different.

### Root Cause

Different Linear MCP implementations have different tool names. The agents need to discover available tools dynamically.

### Solution

1. Document that agents should discover available Linear MCP tools dynamically
2. Update agent prompts to use pattern matching (`mcp__linear__*`) to find tools
3. Add fallback handling if expected tools don't exist

### Files to Modify

1. `marathon-ralph/agents/init.md` - Update to discover Linear tools dynamically
2. `marathon-ralph/agents/setup.md` - List available Linear tools for debugging
3. All other agents using Linear MCP

---

## Issue 3: Environment Variable Loading

**Status:** FIXED (documented in README, .mcp.json uses ${LINEAR_API_KEY})
**Priority:** High
**Component:** Plugin configuration

### Description

The `.env` file exists with `LINEAR_API_KEY` but the plugin needs to ensure this is loaded when the MCP server starts.

### Root Cause

Claude Code plugins using `.mcp.json` may not automatically load `.env` files. The environment variable needs to be available when the MCP server command is executed.

### Solution

1. Use `dotenv` to load `.env` before starting
2. Or require user to `export LINEAR_API_KEY` before running
3. Or configure the plugin to read from `.env` directly

### Workarounds

The user can run:

```bash
source .env && claude --plugin-dir marathon-ralph
```

Or add to their shell profile.

---

## Issue 4: Spec File Path Resolution

**Status:** Open
**Priority:** Medium
**Component:** commands/start.md

### Description

The spec file is located at `marathon-ralph/examples/app_spec.txt` but the start command needs to correctly resolve relative paths.

### Solution

Update `commands/start.md` to:

1. Support both absolute and relative paths
2. Check if file exists before proceeding
3. Store absolute path in state file

---

## Summary

| Issue | Priority | Status | Notes |
|-------|----------|--------|-------|
| Linear MCP OAuth | Critical | FIXED | Using API key via Bearer token header |
| MCP Tool Names | Medium | FIXED | Using official Linear MCP server |
| Environment Variables | High | FIXED | Documented in README, used in config |
| Spec File Paths | Medium | Open | Minor issue |
| Session Restart | Critical | UNDERSTOOD | User must restart Claude after setup |

### Quick Fix Steps

1. The `.env` file already has `LINEAR_API_KEY`
2. Linear MCP server has been added via CLI with API key auth
3. **User must restart Claude Code session** for tools to be available
4. Then run: `/marathon-ralph:start marathon-ralph/examples/app_spec.txt`

---

## Issue 5: MCP Server Addition Requires Session Restart

**Status:** UNDERSTOOD - Requires user action
**Priority:** Critical
**Component:** MCP server lifecycle

### Description

Adding an MCP server via CLI (`claude mcp add`) adds it to the configuration, but the running Claude session needs to be restarted to actually use the new MCP server's tools.

### Root Cause

MCP servers are initialized when Claude Code starts. Adding a server mid-session only updates the configuration file but doesn't instantiate the new server connection.

### Solution Implemented

The Linear MCP server has been added with API key authentication:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp \
  --header "Authorization: Bearer $LINEAR_API_KEY"
```

This was successfully added to the project config:

- File: `/Users/sigex/.claude.json`
- Server shows as "Connected" in `claude mcp list`

### Required User Action

**To complete the setup, the user must:**

1. Exit the current Claude Code session
2. Ensure `LINEAR_API_KEY` is set in the environment:

   ```bash
   source .env
   ```

3. Start a new Claude Code session:

   ```bash
   claude
   ```

4. The Linear MCP tools (`mcp__linear__*`) will now be available
5. Run the marathon:

   ```bash
   /marathon-ralph:start marathon-ralph/examples/app_spec.txt
   ```

### Plugin MCP Configuration

Both `.mcp.json` and `plugin.json` have been updated to include the Linear MCP server configuration. This should work when the plugin is properly loaded in a fresh session:

**`.mcp.json`:**

```json
{
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    }
  }
}
```

**`plugin.json` (inline mcpServers):**

```json
{
  "name": "marathon-ralph",
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp",
      "headers": {
        "Authorization": "Bearer ${LINEAR_API_KEY}"
      }
    }
  }
}
```
