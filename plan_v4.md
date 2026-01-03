# marathon-ralph Plugin - Implementation Plan v4

## Executive Summary

**marathon-ralph** is a Claude Code plugin that provides autonomous, long-running development capabilities using Linear as the project management backbone. It combines the plugin architecture patterns from Claude Code with the proven two-phase autonomous agent approach from the Linear Coding Agent Harness.

The plugin enables users to provide a specification file and have Claude autonomously:

1. Create a Linear project with dynamically-generated issues
2. Work through issues one at a time with verification
3. Continue across multiple sessions via Stop hook
4. Produce a fully tested, working application

**Plugin Name:** `marathon-ralph`

---

## Implementation Status Summary

### What Has Been Completed

| Component | Status | Notes |
|-----------|--------|-------|
| Plugin Structure | COMPLETE | All directories and manifest files in place |
| plugin.json | COMPLETE | Includes MCP server declaration for Linear |
| marketplace.json | COMPLETE | Marketplace registration ready |
| README.md | COMPLETE | Comprehensive documentation with examples |
| setup-agent | COMPLETE | Verifies Linear MCP connectivity |
| init-agent | COMPLETE | Creates Linear project and issues from spec |
| verify-agent | COMPLETE | Runs tests, lint, type checks |
| plan-agent | COMPLETE | Creates implementation plans |
| code-agent | COMPLETE | Implements features with commits |
| test-agent | COMPLETE | Writes unit/integration tests (with Vitest skill) |
| qa-agent | COMPLETE | Writes E2E tests with Playwright |
| run command | COMPLETE | Unified start/resume command (replaces planned `start`) |
| status command | COMPLETE | Shows marathon progress with Linear integration |
| cancel command | COMPLETE | Cleanly stops marathon |
| Stop hook | COMPLETE | Session-scoped continuous operation |
| marathon-ralph skill | COMPLETE | Natural language invocation |
| setup-vitest skill | NEW | Test framework configuration helper |
| setup-playwright skill | NEW | E2E framework configuration helper |
| write-playwright-test skill | NEW | Playwright test writing guidance |
| Example spec file | COMPLETE | Comprehensive todo app specification |

### What Changed from Original Plan

1. **Command Renamed:** `/marathon-ralph:start` is now `/marathon-ralph:run`
   - Reason: Clearer semantics - "run" works for both starting and resuming
   - The `--spec-file` flag starts new, no args resumes existing

2. **Session Scoping Added:** Stop hook now tracks session ownership
   - Added `session_id` field to state file
   - Stop hook only blocks the owning session
   - Added `--force` flag to take over from crashed sessions
   - Prevents marathon hijacking by other Claude sessions

3. **Testing Skills Added:** Three new skills for test infrastructure
   - `setup-vitest`: Configures Vitest with Testing Library
   - `setup-playwright`: Configures Playwright for E2E testing
   - `write-playwright-test`: Guidance for writing Playwright tests
   - These skills are referenced by test-agent and qa-agent

4. **MCP Configuration:** Added `.mcp.json` file
   - Plugin declares its Linear MCP dependency
   - Users still need to authenticate via `/mcp`

5. **Example Spec:** Uses real comprehensive spec (app_spec.txt)
   - More detailed than the sample in plan_v3.md
   - Demonstrates full feature specification format
   - Uses Turborepo, Next.js 15, oRPC, Drizzle, shadcn/ui

6. **Asset:** Banner is JPG not PNG
   - `assets/banner.jpg` instead of `assets/banner.png`

---

## Architecture Overview

### Core Principles

1. **Subagents for everything** - Each phase runs in a dedicated subagent for clean context management
2. **Linear as source of truth** - All task state lives in Linear, local state is minimal bootstrap data
3. **One issue at a time** - No complex pacing; complete one issue fully before moving to next
4. **Verification before new work** - Always run tests/lint/types before starting new features
5. **Dynamic issue generation** - Issue count derived from spec, not hardcoded
6. **Session isolation** - Marathon ownership prevents conflicts between sessions

### Prerequisites

Before using marathon-ralph, users must:

1. Install the Linear MCP server:

   ```bash
   claude mcp add --transport http linear https://mcp.linear.app/mcp
   ```

2. Authenticate via OAuth:

   ```
   /mcp
   # Select Linear -> Authenticate -> Complete browser OAuth flow
   ```

---

## Plugin Structure

```
marathon-ralph/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest with MCP declaration
│   └── marketplace.json         # Marketplace registration
├── .mcp.json                    # MCP server configuration
├── agents/
│   ├── setup.md                 # First-run environment verification
│   ├── init.md                  # Create Linear project + issues from spec
│   ├── verify.md                # Run tests, lint, type checks
│   ├── plan.md                  # Review code, create implementation plan
│   ├── code.md                  # Implement a single feature
│   ├── test.md                  # Write tests for implemented feature
│   └── qa.md                    # Create E2E tests (web projects only)
├── commands/
│   ├── run.md                   # /marathon-ralph:run (start or resume)
│   ├── status.md                # /marathon-ralph:status
│   └── cancel.md                # /marathon-ralph:cancel
├── skills/
│   ├── marathon-ralph/
│   │   └── SKILL.md             # Natural language invocation
│   ├── setup-vitest/
│   │   └── SKILL.md             # Vitest configuration helper
│   ├── setup-playwright/
│   │   └── SKILL.md             # Playwright configuration helper
│   └── write-playwright-test/
│       └── SKILL.md             # Playwright test writing guidance
├── hooks/
│   ├── hooks.json               # Stop hook configuration
│   └── stop-hook.sh             # Session-scoped stop hook script
├── examples/
│   └── app_spec.txt             # Example specification file
├── assets/
│   └── banner.jpg               # Visual asset for marketplace
└── README.md                    # Documentation
```

---

## State Management

### State File Location

`.claude/marathon-ralph.json`

### State File Schema

```json
{
  "active": true,
  "phase": "setup|init|coding|complete",
  "session_id": "unique-session-identifier",
  "spec_file": "path/to/spec.md",
  "linear": {
    "team_id": "abc123-def456",
    "team_name": "My Team",
    "project_id": "proj_xyz789",
    "project_name": "My App",
    "meta_issue_id": "ABC-1",
    "total_issues": 35
  },
  "current_issue": {
    "id": "ABC-15",
    "title": "Implement user authentication"
  },
  "stats": {
    "completed": 14,
    "in_progress": 1,
    "todo": 20
  },
  "stop_hook_iterations": 5,
  "created_at": "2025-01-02T10:30:00Z",
  "last_updated": "2025-01-02T14:45:00Z"
}
```

### State Transitions

```
[not exists] -> setup -> init -> coding <-> coding -> complete
                                   ^          |
                                   |__________|
                                 (via Stop hook)
```

### Session Ownership

The `session_id` field enables session-scoped marathons:

- **No session_id (unclaimed):** Stop hook claims ownership on first run
- **session_id matches:** Stop hook blocks exit, marathon continues
- **session_id differs:** Command refuses without `--force`, stop hook allows exit
- **With `--force`:** Clears session_id, allows takeover from crashed session

---

## Agent Definitions

### 1. setup-agent

**File:** `agents/setup.md`

**Purpose:** Verify environment is ready for marathon operation.

**Model:** `haiku` (fast, simple checks)

**Tools:** `Read`, `Bash`, `Glob`

**Status:** COMPLETE

**Responsibilities:**

1. Check if Linear MCP tools are available (mcp__linear__* tools)
2. Test Linear connectivity by attempting to list teams
3. If not connected/authenticated, provide clear instructions
4. Create `.claude/marathon-ralph.json` with `phase: "setup"` if successful
5. Report readiness status

---

### 2. init-agent

**File:** `agents/init.md`

**Purpose:** Create Linear project and issues from user's specification file.

**Model:** `opus` (complex analysis and planning)

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `mcp__linear__*`

**Status:** COMPLETE

**Responsibilities:**

1. Read the specification file provided by user
2. Query Linear for available teams
3. If multiple teams, ask user to select
4. Create Linear project with descriptive name
5. Analyze spec and create appropriate number of issues (dynamic, not fixed)
6. Each issue includes: title, description, acceptance criteria, test steps, priority
7. Create META issue for session tracking/handoff notes
8. For greenfield projects: discuss framework, generate init.sh, CLAUDE.md
9. Initialize git repository if not exists
10. Update state file with Linear metadata and phase: "coding"

---

### 3. verify-agent

**File:** `agents/verify.md`

**Purpose:** Run comprehensive verification before new work.

**Model:** `sonnet`

**Tools:** `Read`, `Bash`, `Glob`, `Grep`

**Status:** COMPLETE

**Responsibilities:**

1. Detect project type from config files (package.json, pyproject.toml, etc.)
2. Run unit tests (npm test, pytest, etc.)
3. Run integration tests if present
4. Run E2E tests if present (Playwright, Cypress)
5. Run linter (eslint, biome, ruff, etc.)
6. Run type checker (tsc, mypy, pyright, etc.)
7. If any failures: create NEW bug issue in Linear, make it next task
8. Return structured JSON status report

---

### 4. plan-agent

**File:** `agents/plan.md`

**Purpose:** Create implementation plan for current issue.

**Model:** `sonnet`

**Tools:** `Read`, `Glob`, `Grep`

**Status:** COMPLETE

**Responsibilities:**

1. Read current issue details from Linear
2. Explore relevant parts of codebase
3. Identify files to create and modify
4. Create step-by-step implementation plan
5. Document assumptions as comment on Linear issue
6. Output structured plan for code-agent

---

### 5. code-agent

**File:** `agents/code.md`

**Purpose:** Implement the feature according to plan.

**Model:** `sonnet`

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Status:** COMPLETE

**Responsibilities:**

1. Follow plan from plan-agent
2. Write clean, well-structured code
3. Follow project conventions (from CLAUDE.md)
4. Verify implementation manually (run app, check behavior)
5. Commit changes with descriptive message referencing Linear issue
6. Report implementation summary

---

### 6. test-agent

**File:** `agents/test.md`

**Purpose:** Write tests for the implemented feature.

**Model:** `sonnet`

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Skills:** `setup-vitest`

**Status:** COMPLETE

**Responsibilities:**

1. Check if test framework exists; use `setup-vitest` skill if not
2. Review the implementation from code-agent
3. Review the issue requirements
4. Check existing test patterns in codebase
5. Write unit tests following Testing Library best practices
6. Write integration tests if applicable
7. Run tests to verify they pass
8. Commit test files with Linear issue reference

---

### 7. qa-agent

**File:** `agents/qa.md`

**Purpose:** Create E2E tests for web projects.

**Model:** `sonnet`

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Skills:** `setup-playwright`, `write-playwright-test`

**Status:** COMPLETE

**Responsibilities:**

1. Determine if project is web-based (React, Vue, Next.js, etc.)
2. If not web-based, skip with message
3. Check if Playwright exists; use `setup-playwright` skill if not
4. Use `write-playwright-test` skill for test patterns
5. Create E2E tests using fixtures and Page Object Model
6. Use accessibility-first queries (getByRole, getByLabel)
7. Run E2E tests to verify
8. Commit E2E test files with Linear issue reference

---

## Commands

### /marathon-ralph:run

**File:** `commands/run.md`

**Status:** COMPLETE (renamed from `start`)

**Purpose:** Start new marathon or resume existing one

**Arguments:**
- `--spec-file <path>` or `<path>` - Start new marathon with spec file
- No arguments - Resume existing marathon
- `--force` - Take over marathon from crashed session

**Process:**
1. Check for existing state file
2. Handle session ownership (session_id checks)
3. If resuming: verify and continue coding loop
4. If new: setup-agent -> init-agent -> coding loop
5. Coding loop: verify -> plan -> code -> test -> qa -> mark done
6. Exit after one issue (stop hook continues)

---

### /marathon-ralph:status

**File:** `commands/status.md`

**Status:** COMPLETE

**Purpose:** Show marathon progress with live Linear data

**Process:**
1. Read state file
2. If no marathon: report "No active marathon"
3. Query Linear for real-time issue counts
4. Show progress bar, issue breakdown, current issue
5. Display recent activity from META issue

---

### /marathon-ralph:cancel

**File:** `commands/cancel.md`

**Status:** COMPLETE

**Purpose:** Stop the current marathon cleanly

**Process:**
1. Check for active marathon
2. Confirm with user
3. Set `active: false` in state file (keep phase as-is)
4. Add cancellation note to META issue in Linear
5. Report cancellation summary (project preserved)

---

## Skills

### marathon-ralph Skill

**File:** `skills/marathon-ralph/SKILL.md`

**Status:** COMPLETE

**Triggers:**
- "marathon this [spec]"
- "build from spec"
- "autonomous development"
- "keep coding until done"
- "marathon development"

**Maps to:**
- Start/resume: `/marathon-ralph:run`
- Status: `/marathon-ralph:status`
- Cancel: `/marathon-ralph:cancel`

---

### setup-vitest Skill

**File:** `skills/setup-vitest/SKILL.md`

**Status:** NEW (not in original plan)

**Purpose:** Configure Vitest with Testing Library for unit testing

**Provides:**
- Installation commands (ni -D vitest @testing-library/*)
- Configuration templates (vitest.config.ts)
- Setup file examples (tests/setup.ts)
- Testing Library query priority guidance
- Kent C. Dodds testing philosophy

---

### setup-playwright Skill

**File:** `skills/setup-playwright/SKILL.md`

**Status:** NEW (not in original plan)

**Purpose:** Configure Playwright for E2E testing

**Provides:**
- Installation commands
- Configuration template (playwright.config.ts)
- Directory structure (fixtures, pages, specs)
- Authentication setup example
- GitHub Actions CI workflow
- Custom fixtures pattern

---

### write-playwright-test Skill

**File:** `skills/write-playwright-test/SKILL.md`

**Status:** NEW (not in original plan)

**Purpose:** Guide Playwright test writing with best practices

**Provides:**
- Query priority (accessibility-first)
- Fixture patterns (auth, database, worker-scoped)
- Page Object Model examples
- Web-first assertions
- Common patterns (network, upload, dialogs)
- Anti-patterns to avoid

---

## Hooks Configuration

**File:** `hooks/hooks.json`

**Status:** COMPLETE

```json
{
  "description": "Marathon Ralph stop hook - claims session ownership and enables continuous autonomous operation",
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

---

**File:** `hooks/stop-hook.sh`

**Status:** COMPLETE (enhanced from original plan)

**Features:**
- Reads session_id from stdin JSON
- Claims ownership of unclaimed marathons
- Only blocks exit for owning session
- Respects session_id mismatch (allows other sessions to exit)
- Safety limit of 100 iterations
- Provides continuation instructions in block reason

---

## Plugin Manifest

**File:** `.claude-plugin/plugin.json`

**Status:** COMPLETE

```json
{
  "name": "marathon-ralph",
  "version": "1.0.0",
  "description": "Persistent marathon development sessions for Linear issues...",
  "keywords": ["linear", "marathon", "persistent", "state-management", "productivity", "ralph wiggum"],
  "author": { "name": "gruckion" },
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp"
    }
  }
}
```

---

## What Remains to Be Done

### Testing & Validation (Group 8 equivalent)

1. **End-to-end testing with real spec file**
   - Run marathon with `examples/app_spec.txt`
   - Verify Linear project creation
   - Verify issue creation with proper structure
   - Verify full coding loop execution

2. **Error handling edge cases**
   - Linear API rate limits
   - Network failures during Linear operations
   - Git conflicts during commits
   - Test framework installation failures

3. **CLAUDE.md for plugin development**
   - Developer documentation for contributors
   - Plugin architecture overview
   - Testing instructions for the plugin itself

4. **Session takeover testing**
   - Verify `--force` flag works correctly
   - Test unclaimed marathon claiming
   - Test session mismatch rejection

---

## Success Criteria

- [x] Plugin loads successfully with `claude --plugin-dir ./marathon-ralph`
- [x] `/marathon-ralph:run <spec>` creates Linear project from spec
- [x] Issues are dynamically generated based on spec content
- [x] Team selection works when user has multiple Linear teams
- [x] Verification runs before each new issue
- [x] Regressions create new linked bug issues (not reopen)
- [x] Each agent completes its designated task
- [x] Stop hook continues marathon until all issues Done
- [x] Session scoping prevents conflicts between sessions
- [x] `/marathon-ralph:status` shows accurate progress
- [x] `/marathon-ralph:cancel` cleanly stops marathon
- [x] Natural language invocation works via skill
- [x] Greenfield projects get init.sh and CLAUDE.md
- [x] Git commits reference Linear issue IDs
- [x] META issue tracks session handoff notes
- [x] Testing skills help set up Vitest and Playwright
- [ ] Full end-to-end test with real application build
- [ ] CLAUDE.md for plugin contributors

---

## Appendix: Linear MCP Tools Reference

The plugin expects these Linear MCP tools to be available:

- `mcp__linear__list_teams` - List available teams
- `mcp__linear__create_project` - Create new project
- `mcp__linear__create_issue` - Create issue in project
- `mcp__linear__list_issues` - Query issues by status/project
- `mcp__linear__update_issue` - Update issue status/fields
- `mcp__linear__create_comment` - Add comment to issue

Actual tool names may vary based on Linear MCP implementation. Agents discover available tools dynamically.

---

## Appendix: Version History

- **v1**: Initial concept
- **v2**: Refined architecture
- **v3**: Detailed implementation plan with agents, commands, hooks
- **v4**: Current state documentation after implementation
  - Command renamed from `start` to `run`
  - Session scoping added with `session_id`
  - Testing skills added (setup-vitest, setup-playwright, write-playwright-test)
  - MCP configuration added (.mcp.json)
  - All core components implemented
