# Marathon Ralph Plugin

Persistent marathon development sessions for Linear issues - continue working on the same task across multiple Claude sessions with automatic state management and progress tracking.

## Overview

Marathon Ralph extends the [Chief Wiggum](../chief-wiggum/) iterative development approach to support **persistent, multi-session workflows** tied to Linear issues. Instead of completing a task in a single session, Marathon Ralph enables you to:

- Start a "marathon" on a Linear issue
- Work across multiple Claude sessions
- Track progress and iteration history
- Resume exactly where you left off
- Stay focused on the same task until completion

## Prerequisites

### Linear MCP Setup

Marathon Ralph requires the Linear MCP server to be configured:

1. Install the Linear MCP server
2. Configure your Linear API token
3. Ensure you can query Linear issues via MCP

## Quick Start

1. Check marathon status:
   ```
   /marathon-ralph:status
   ```

2. If no active marathon, you'll see:
   ```
   No active marathon session.
   ```

3. If an active marathon exists, you'll see details about:
   - The Linear issue being worked on
   - Current session status
   - Iteration count and progress

## Commands

### /marathon-ralph:status

Check the current marathon session status.

```
/marathon-ralph:status
```

**Output:**
- If no active session: "No active marathon session."
- If active: Displays issue ID, status, iterations, and timestamps

## State Management

Marathon Ralph stores session state in `.claude/marathon-ralph.json` in your working directory. This file contains:

- Linear issue identifier
- Session status (active/paused)
- Start timestamp
- Iteration count
- Last activity timestamp

The `.claude/` directory should be added to `.gitignore` as it contains local session state.

## How It Works

1. **Start**: Begin a marathon on a Linear issue
2. **Work**: Claude works iteratively on the task
3. **Persist**: State is saved between sessions
4. **Resume**: Pick up where you left off in a new session
5. **Complete**: Mark the marathon done when the issue is resolved

## Directory Structure

```
marathon-ralph/
├── .claude-plugin/       # Plugin metadata
│   ├── plugin.json       # Plugin name, version, description
│   └── marketplace.json  # Marketplace listing info
├── commands/             # Slash command definitions
│   └── status.md         # /marathon-ralph:status command
└── README.md             # This file
```

## Related Projects

- [Chief Wiggum](../chief-wiggum/) - Single-session iterative development loops
- [Ralph Wiggum technique](https://ghuntley.com/ralph/) - Original iterative AI methodology
