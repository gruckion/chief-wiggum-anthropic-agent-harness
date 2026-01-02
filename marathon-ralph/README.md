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

1. Add Linear MCP server:
   ```bash
   claude mcp add --transport http linear https://mcp.linear.app/mcp
   ```

2. Authenticate via OAuth:
   ```
   /mcp
   # Select Linear → Authenticate → Complete browser OAuth flow
   ```

## Quick Start

1. Check marathon status:
   ```
   /marathon-ralph:status
   ```

2. Start a new marathon from a spec file:
   ```
   /marathon-ralph:start --spec-file ./my-project-spec.md
   ```

3. The marathon will:
   - Verify Linear MCP is connected
   - Create a Linear project with issues from your spec
   - Begin the coding loop automatically

## Commands

### /marathon-ralph:start

Start a new marathon or resume an existing one.

```
/marathon-ralph:start --spec-file <path>
/marathon-ralph:start <path>
```

**Arguments:**
- `--spec-file <path>` - Path to the specification file (markdown)
- `<path>` - Direct path to spec file

**Behavior:**
- If no marathon exists: Creates new project and issues in Linear
- If marathon is in "coding" phase: Resumes the coding loop
- If marathon is "complete": Asks to start a new marathon

### /marathon-ralph:status

Check the current marathon session status.

```
/marathon-ralph:status
```

**Output:**
- If no active session: "No active marathon session."
- If active: Displays phase, current issue, progress, and timestamps

## The Coding Loop Workflow

Marathon Ralph uses a **verify → plan → code** workflow for each issue:

```
┌─────────────────────────────────────────────────┐
│                  CODING LOOP                     │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────┐                                    │
│  │  VERIFY  │ ← Run tests, lint, type checks    │
│  └────┬─────┘                                    │
│       │                                          │
│       ▼                                          │
│  ┌──────────┐                                    │
│  │GET ISSUE │ ← Fetch next Todo from Linear     │
│  └────┬─────┘                                    │
│       │                                          │
│       ▼                                          │
│  ┌──────────┐                                    │
│  │   PLAN   │ ← Analyze & create impl plan      │
│  └────┬─────┘                                    │
│       │                                          │
│       ▼                                          │
│  ┌──────────┐                                    │
│  │   CODE   │ ← Implement the feature           │
│  └────┬─────┘                                    │
│       │                                          │
│       ▼                                          │
│  Mark issue "Done" in Linear                     │
│  Continue to next issue...                       │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Phase 1: Verify

The **verify-agent** runs before starting any new work:

- **Unit Tests**: Runs `npm test`, `pytest`, etc.
- **Integration Tests**: Runs if configured
- **E2E Tests**: Runs if Playwright/Cypress is present
- **Linting**: Runs `npm run lint`, `ruff check`, etc.
- **Type Checking**: Runs `tsc --noEmit`, `mypy`, etc.

**On Failure:**
- A bug issue is automatically created in Linear
- The bug becomes the next issue to fix
- No new features are started until verification passes

### Phase 2: Get Issue

Issues are fetched from Linear:
- Filters for "Todo" status in the marathon project
- Sorts by priority (P0 → P1 → P2 → P3)
- Oldest issues of each priority come first
- Issue is marked "In Progress" when selected

### Phase 3: Plan

The **plan-agent** creates an implementation plan:

- Reads the issue description and acceptance criteria
- Explores the codebase to understand context
- Identifies files to create and modify
- Documents the implementation approach
- Adds planning notes as a comment on the Linear issue

**Output:** A structured implementation plan for the code agent.

### Phase 4: Code

The **code-agent** implements the feature:

- Follows the implementation plan exactly
- Writes clean code following project conventions
- Verifies the implementation works
- Creates a commit with the Linear issue ID
- Does NOT write tests (that's a future test-agent's job)

**Output:** Working code committed to the repository.

## Issue Progression

```
Linear Status Flow:
┌──────┐    ┌─────────────┐    ┌──────┐
│ Todo │ →  │ In Progress │ →  │ Done │
└──────┘    └─────────────┘    └──────┘
   ▲                               │
   │                               │
   └───────────────────────────────┘
         (Bug issues may be created)
```

## State Management

Marathon Ralph stores session state in `.claude/marathon-ralph.json` in your working directory. This file contains:

```json
{
  "active": true,
  "phase": "coding",
  "spec_file": "/path/to/spec.md",
  "linear": {
    "team_id": "abc123",
    "team_name": "My Team",
    "project_id": "proj_xyz",
    "project_name": "My Project",
    "meta_issue_id": "ABC-1",
    "total_issues": 15
  },
  "current_issue": {
    "id": "ABC-5",
    "title": "Implement user authentication"
  },
  "stats": {
    "completed": 4,
    "in_progress": 1,
    "todo": 10
  },
  "created_at": "2025-01-02T10:00:00Z",
  "last_updated": "2025-01-02T14:30:00Z"
}
```

### Phases

| Phase | Description |
|-------|-------------|
| `setup` | Verifying Linear MCP connection |
| `init` | Creating Linear project and issues |
| `coding` | Active development loop |
| `complete` | All issues finished |

The `.claude/` directory should be added to `.gitignore` as it contains local session state.

## Agent Sequence

Marathon Ralph uses specialized subagents for each task:

| Agent | Purpose | Model |
|-------|---------|-------|
| `marathon-setup` | Verify Linear MCP is connected | haiku |
| `marathon-init` | Create Linear project and issues | opus |
| `marathon-verify` | Run tests, lint, type checks | sonnet |
| `marathon-plan` | Create implementation plan | sonnet |
| `marathon-code` | Implement the feature | sonnet |

## Directory Structure

```
marathon-ralph/
├── .claude-plugin/       # Plugin metadata
│   ├── plugin.json       # Plugin name, version, description
│   └── marketplace.json  # Marketplace listing info
├── agents/               # Subagent definitions
│   ├── setup.md          # Environment verification
│   ├── init.md           # Project initialization
│   ├── verify.md         # Codebase health checks
│   ├── plan.md           # Implementation planning
│   └── code.md           # Feature implementation
├── commands/             # Slash command definitions
│   ├── start.md          # /marathon-ralph:start
│   └── status.md         # /marathon-ralph:status
└── README.md             # This file
```

## How It Works

1. **Start**: Begin a marathon with a spec file
2. **Setup**: Verify Linear MCP is connected
3. **Init**: Create Linear project with issues from spec
4. **Loop**: For each issue:
   - Verify codebase health
   - Plan the implementation
   - Code the feature
   - Mark issue done
5. **Complete**: When all issues are done, marathon ends

## Future Enhancements

Coming in future groups:
- **Test Agent**: Automatically write tests after implementation
- **QA Agent**: E2E testing for web projects
- **Stop Hook**: Automatic session continuation
- **Cancel Command**: Abort an in-progress marathon

## Related Projects

- [Chief Wiggum](../chief-wiggum/) - Single-session iterative development loops
- [Ralph Wiggum technique](https://ghuntley.com/ralph/) - Original iterative AI methodology
