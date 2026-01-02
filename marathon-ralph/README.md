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
   # Select Linear -> Authenticate -> Complete browser OAuth flow
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

## Natural Language Usage

Marathon Ralph supports natural language invocation through its skill definition. You do not need to remember exact command syntax - just describe what you want:

### Starting a Marathon

- "Marathon this spec.md until complete"
- "Build from my-project-spec.md"
- "Keep coding until all the features in spec.md are done"
- "Autonomous development from the spec file"
- "Marathon this project"

### Checking Progress

- "How's the marathon going?"
- "What's the marathon status?"
- "Show me marathon progress"
- "How far along are we?"

### Stopping a Marathon

- "Stop the marathon"
- "Cancel the marathon session"
- "Abort the current marathon"
- "I need to stop autonomous development"

The skill triggers on phrases containing:

- "marathon this" or "marathon development"
- "build from spec"
- "autonomous development"
- "keep coding until done"

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

### /marathon-ralph:cancel

Cancel the active marathon and stop autonomous processing.

```
/marathon-ralph:cancel
```

**Behavior:**

1. Checks for active marathon in `.claude/marathon-ralph.json`
2. If no active marathon: Reports "No active marathon to cancel"
3. Shows current progress and asks for confirmation
4. If confirmed:
   - Sets `active: false` in state file
   - Adds cancellation note to META issue in Linear
   - Reports summary and how to resume
5. Preserves Linear project and issues (does NOT delete them)

**Resume After Cancel:**

To resume a cancelled marathon, run `/marathon-ralph:start` again. The existing Linear project will be detected and work continues from where it left off.

## The Coding Loop Workflow

Marathon Ralph uses a **verify -> plan -> code -> test -> qa** workflow for each issue:

```
+----------------------------------------------+
|                  CODING LOOP                 |
+----------------------------------------------+
|                                              |
|  +----------+                                |
|  |  VERIFY  | <- Run tests, lint, type checks|
|  +----+-----+                                |
|       |                                      |
|       v                                      |
|  +----------+                                |
|  |GET ISSUE | <- Fetch next Todo from Linear |
|  +----+-----+                                |
|       |                                      |
|       v                                      |
|  +----------+                                |
|  |   PLAN   | <- Analyze & create impl plan  |
|  +----+-----+                                |
|       |                                      |
|       v                                      |
|  +----------+                                |
|  |   CODE   | <- Implement the feature       |
|  +----+-----+                                |
|       |                                      |
|       v                                      |
|  +----------+                                |
|  |   TEST   | <- Write unit/integration tests|
|  +----+-----+                                |
|       |                                      |
|       v                                      |
|  +----------+                                |
|  |    QA    | <- Write E2E tests (web only)  |
|  +----+-----+                                |
|       |                                      |
|       v                                      |
|  Mark issue "Done" in Linear                 |
|  Continue to next issue...                   |
|                                              |
+----------------------------------------------+
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
- Sorts by priority (P0 -> P1 -> P2 -> P3)
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
- Does NOT write tests (that's the test-agent's job)

**Output:** Working code committed to the repository.

### Phase 5: Test

The **test-agent** writes tests for the implementation:

- Reviews the files modified by code-agent
- Checks acceptance criteria for test coverage needs
- Follows existing test patterns and frameworks
- Writes unit tests for individual functions/components
- Writes integration tests for feature workflows
- Covers edge cases and error handling
- Creates a commit with the test files

**Output:** Comprehensive test suite committed to the repository.

### Phase 6: QA

The **qa-agent** creates E2E tests for web projects:

- First determines if this is a web project (React, Vue, Next.js, etc.)
- **If NOT a web project:** Skips with message and proceeds
- **If web project:**
  - Uses existing E2E framework (Playwright or Cypress)
  - Tests complete user flows
  - Covers success and error scenarios
  - Creates a commit with E2E tests

**Output:** E2E tests committed (or skipped for non-web projects).

## Issue Progression

```
Linear Status Flow:
+------+    +-------------+    +------+
| Todo | -> | In Progress | -> | Done |
+------+    +-------------+    +------+
   ^                               |
   |                               |
   +-------------------------------+
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

| Phase      | Description                        |
| ---------- | ---------------------------------- |
| `setup`    | Verifying Linear MCP connection    |
| `init`     | Creating Linear project and issues |
| `coding`   | Active development loop            |
| `complete` | All issues finished                |

The `.claude/` directory should be added to `.gitignore` as it contains local session state.

## Skill Definition

Marathon Ralph includes a skill file at `skills/marathon-ralph/SKILL.md` that enables natural language invocation. The skill:

- **Name**: marathon-ralph
- **Triggers on**: "marathon this", "build from spec", "autonomous development", "keep coding until done"
- **Provides**: Instructions for when and how to invoke marathon commands

The skill allows Claude to recognize when users want marathon functionality without using explicit slash commands. For example:

- User says: "Marathon this spec.md until complete"
- Claude recognizes the marathon intent and runs `/marathon-ralph:start --spec-file spec.md`

### Skill Location

```
skills/
  marathon-ralph/
    SKILL.md
```

## Agent Sequence

Marathon Ralph uses specialized subagents for each task:

| Agent             | Purpose                          | Model  |
| ----------------- | -------------------------------- | ------ |
| `marathon-setup`  | Verify Linear MCP is connected   | haiku  |
| `marathon-init`   | Create Linear project and issues | opus   |
| `marathon-verify` | Run tests, lint, type checks     | sonnet |
| `marathon-plan`   | Create implementation plan       | sonnet |
| `marathon-code`   | Implement the feature            | sonnet |
| `marathon-test`   | Write unit and integration tests | sonnet |
| `marathon-qa`     | Write E2E tests (web projects)   | sonnet |

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
│   ├── code.md           # Feature implementation
│   ├── test.md           # Unit/integration test writing
│   └── qa.md             # E2E test writing (web only)
├── commands/             # Slash command definitions
│   ├── start.md          # /marathon-ralph:start
│   ├── status.md         # /marathon-ralph:status
│   └── cancel.md         # /marathon-ralph:cancel
├── hooks/                # Claude Code hooks
│   ├── hooks.json        # Hook configuration
│   └── stop-hook.sh      # Stop hook for continuous operation
├── skills/               # Skill definitions
│   └── marathon-ralph/
│       └── SKILL.md      # Natural language triggers
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
   - Write unit/integration tests
   - Write E2E tests (web projects only)
   - Mark issue done (only after tests pass)
5. **Complete**: When all issues are done, marathon ends

## Continuous Operation (Stop Hook)

Marathon Ralph uses a **Stop Hook** to enable continuous autonomous operation. When Claude attempts to exit during an active marathon, the hook intercepts the exit and instructs Claude to continue with the next issue.

### How It Works

1. **On Session Exit Attempt**: Claude Code triggers the Stop hook
2. **State Check**: The hook reads `.claude/marathon-ralph.json`
3. **Decision Logic**:
   - If no state file exists: Allow exit (not in a marathon)
   - If `active: false` or `phase: complete`: Allow exit
   - If marathon is active in `coding` phase: Block exit and continue

### Iteration Safety Limit

To prevent infinite loops, the hook tracks iterations and enforces a maximum of **100 iterations** per marathon. If this limit is reached:

- The hook allows exit with a notification
- The marathon is paused (not cancelled)
- Resume by running `/marathon-ralph:start` again

The iteration count is stored in `stop_hook_iterations` in the state file.

### Manually Stopping a Marathon

There are several ways to stop an active marathon:

1. **Cancel Command** (recommended):

   ```
   /marathon-ralph:cancel
   ```

   This cleanly stops the marathon and updates state.

2. **Manual State Edit**:
   Edit `.claude/marathon-ralph.json` and set:

   ```json
   {
     "active": false,
     "phase": "complete"
   }
   ```

3. **Delete State File**:

   ```bash
   rm .claude/marathon-ralph.json
   ```

   This removes all marathon state (use with caution).

### Hook Files

```
hooks/
├── hooks.json      # Hook configuration (registers Stop hook)
└── stop-hook.sh    # Stop hook script (bash)
```

The `hooks.json` configuration:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### Linear MCP Not Connected

**Symptom**: Marathon fails at setup phase with "Linear MCP not available"

**Solution**:

1. Verify Linear MCP is added:

   ```bash
   claude mcp list
   ```

2. If not listed, add it:

   ```bash
   claude mcp add --transport http linear https://mcp.linear.app/mcp
   ```

3. Authenticate:

   ```
   /mcp
   ```

   Select Linear and complete OAuth flow.

### Marathon Stuck in Coding Phase

**Symptom**: Marathon keeps running but not making progress

**Solution**:

1. Check status: `/marathon-ralph:status`
2. Look for issues in Linear marked "In Progress" but not progressing
3. Cancel and restart: `/marathon-ralph:cancel` then `/marathon-ralph:start`

### State File Corruption

**Symptom**: Commands fail with JSON parse errors

**Solution**:

1. Delete the state file:

   ```bash
   rm .claude/marathon-ralph.json
   ```

2. Start fresh: `/marathon-ralph:start --spec-file your-spec.md`

Note: This loses tracking of the current marathon. Check Linear for actual progress.

### Stop Hook Not Working

**Symptom**: Claude exits instead of continuing to next issue

**Solution**:

1. Verify hook file exists: `hooks/stop-hook.sh`
2. Check it is executable: `chmod +x hooks/stop-hook.sh`
3. Verify hooks.json is valid JSON
4. Check state file has `active: true` and `phase: coding`

### Iteration Limit Reached

**Symptom**: Marathon stops with "iteration limit reached"

**Solution**:

This is a safety feature. To continue:

1. Reset iteration count in state file (set `stop_hook_iterations: 0`)
2. Run `/marathon-ralph:start` to resume

### Tests Keep Failing

**Symptom**: Verify phase keeps creating bug issues

**Solution**:

1. Fix the underlying test failures manually
2. The marathon will automatically continue once tests pass
3. Or cancel the marathon, fix issues, and restart

### Linear API Rate Limits

**Symptom**: Linear operations fail intermittently

**Solution**:

1. The marathon will retry on next iteration
2. If persistent, wait a few minutes and resume
3. Check Linear status page for outages

## Related Projects

- [Chief Wiggum](../chief-wiggum/) - Single-session iterative development loops
- [Ralph Wiggum technique](https://ghuntley.com/ralph/) - Original iterative AI methodology
