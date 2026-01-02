# marathon-ralph Plugin - Implementation Plan v3

## Executive Summary

**marathon-ralph** is a Claude Code plugin that provides autonomous, long-running development capabilities using Linear as the project management backbone. It combines the plugin architecture patterns from Claude Code with the proven two-phase autonomous agent approach from the Linear Coding Agent Harness.

The plugin enables users to provide a specification file and have Claude autonomously:

1. Create a Linear project with dynamically-generated issues
2. Work through issues one at a time with verification
3. Continue across multiple sessions via Stop hook
4. Produce a fully tested, working application

**Plugin Name:** `marathon-ralph`

---

## Architecture Overview

### Core Principles

1. **Subagents for everything** - Each phase runs in a dedicated subagent for clean context management
2. **Linear as source of truth** - All task state lives in Linear, local state is minimal bootstrap data
3. **One issue at a time** - No complex pacing; complete one issue fully before moving to next
4. **Verification before new work** - Always run tests/lint/types before starting new features
5. **Dynamic issue generation** - Issue count derived from spec, not hardcoded

### Prerequisites

Before using marathon-ralph, users must:

1. Install the Linear MCP server:

   ```bash
   claude mcp add --transport http linear https://mcp.linear.app/mcp
   ```

2. Authenticate via OAuth:

   ```
   /mcp
   # Select Linear → Authenticate → Complete browser OAuth flow
   ```

---

## Plugin Structure

```
marathon-ralph/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/
│   ├── setup.md                 # First-run environment verification
│   ├── init.md                  # Create Linear project + issues from spec
│   ├── verify.md                # Run tests, lint, type checks
│   ├── plan.md                  # Review code, create implementation plan
│   ├── code.md                  # Implement a single feature
│   ├── test.md                  # Write tests for implemented feature
│   └── qa.md                    # Create E2E tests (web projects only)
├── commands/
│   ├── start.md                 # /marathon-ralph:start
│   ├── status.md                # /marathon-ralph:status
│   └── cancel.md                # /marathon-ralph:cancel
├── skills/
│   └── marathon-ralph/
│       └── SKILL.md             # Natural language invocation
├── hooks/
│   └── hooks.json               # Stop hook configuration
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
  "created_at": "2025-01-02T10:30:00Z",
  "last_updated": "2025-01-02T14:45:00Z"
}
```

### State Transitions

```
[not exists] → setup → init → coding ↔ coding → complete
                                ↑          ↓
                                └──────────┘
                              (via Stop hook)
```

---

## Agent Definitions

### 1. setup-agent

**File:** `agents/setup.md`

**Purpose:** Verify environment is ready for marathon operation.

**Model:** `haiku` (fast, simple checks)

**Tools:** `Read`, `Bash`, `Glob`

**Responsibilities:**

1. Check if Linear MCP is connected (query available MCP tools)
2. If not connected, provide clear instructions:
   - How to add Linear MCP server
   - How to authenticate via `/mcp`
3. Verify authentication by attempting a simple Linear query
4. Create `.claude/marathon-ralph.json` with `phase: "setup"` if successful
5. Report readiness status

**Prompt:**

```markdown
---
name: marathon-setup
description: Verify Linear MCP is connected and authenticated. Run automatically before marathon operations.
tools: Read, Bash, Glob
model: haiku
---

You are the setup verification agent for marathon-ralph.

Your job is to verify the environment is ready for autonomous development:

1. Check if Linear MCP tools are available by looking for mcp__linear__* tools
2. Test Linear connectivity by querying for teams
3. If Linear is not configured:
   - Explain how to add: `claude mcp add --transport http linear https://mcp.linear.app/mcp`
   - Explain how to authenticate: Run `/mcp`, select Linear, complete OAuth
4. Create or update `.claude/marathon-ralph.json` with phase: "setup"

Report success or failure with clear next steps.
```

---

### 2. init-agent

**File:** `agents/init.md`

**Purpose:** Create Linear project and issues from user's specification file.

**Model:** `opus` (complex analysis and planning)

**Tools:** `Read`, `Write`, `Glob`, `Grep`, `Bash`, `mcp__linear__*`

**Responsibilities:**

1. Read the specification file provided by user
2. Query Linear for available teams
3. If multiple teams, ask user to select (via returned message)
4. Create Linear project with descriptive name
5. Analyze spec and create appropriate number of issues (dynamic, not fixed)
6. Each issue should have:
   - Clear title
   - Detailed description with acceptance criteria
   - Test steps for verification
   - Priority (critical infrastructure first, features later)
7. Create META issue for session tracking/handoff notes
8. For greenfield projects:
   - Discuss framework choice with user (React, Next.js, Vue, etc.)
   - Generate `init.sh` setup script
   - Generate project `CLAUDE.md` with conventions
9. Initialize git repository if not exists
10. Update state file with Linear metadata

**Prompt:**

```markdown
---
name: marathon-init
description: Create Linear project and issues from specification. Used when starting a new marathon.
tools: Read, Write, Edit, Glob, Grep, Bash
model: opus
---

You are the initialization agent for marathon-ralph.

Your job is to set up a new autonomous development project:

## Phase 1: Read Specification
1. Read the spec file path from the state file or arguments
2. Analyze the specification thoroughly
3. Identify all features, components, and requirements

## Phase 2: Linear Setup
1. Query Linear for available teams using mcp__linear__* tools
2. If multiple teams exist, report them and ask user to specify which to use
3. Create a new Linear project with a descriptive name based on the spec

## Phase 3: Issue Creation
1. Break down the spec into discrete, implementable issues
2. Create issues in priority order:
   - P0: Project setup, core infrastructure, configuration
   - P1: Core features, main functionality
   - P2: Secondary features, enhancements
   - P3: Polish, optimization, documentation
3. Each issue MUST include:
   - Clear, actionable title
   - Detailed description with context
   - Acceptance criteria (checkboxes)
   - Test steps for verification
4. Create a META issue titled "[META] Project Progress Tracker" for session notes

## Phase 4: Project Setup (Greenfield)
If this is a new project with no existing code:
1. Discuss framework/stack choice with user based on spec requirements
2. Generate `init.sh` script to bootstrap the project
3. Generate `CLAUDE.md` in the project root with:
   - Project overview
   - Tech stack and conventions
   - File structure
   - Development commands
   - Testing approach

## Phase 5: Finalize
1. Initialize git repository if needed
2. Update `.claude/marathon-ralph.json` with:
   - phase: "coding"
   - Linear team_id, project_id, meta_issue_id
   - total_issues count
3. Report summary of created issues

Do NOT start working on issues. Your job is setup only.
```

---

### 3. verify-agent

**File:** `agents/verify.md`

**Purpose:** Run comprehensive verification before new work.

**Model:** `sonnet`

**Tools:** `Read`, `Bash`, `Glob`, `Grep`

**Responsibilities:**

1. Detect project type and available test infrastructure
2. Run unit tests (npm test, pytest, etc.)
3. Run integration tests if present
4. Run E2E tests if present
5. Run linter (eslint, ruff, etc.)
6. Run type checker (tsc, mypy, pyright, etc.)
7. If any failures:
   - Create NEW bug issue in Linear linked to relevant completed issue
   - Report which checks failed and why
8. Report verification status

**Prompt:**

```markdown
---
name: marathon-verify
description: Run comprehensive verification (tests, lint, types) before starting new work. MUST pass before coding.
tools: Read, Bash, Glob, Grep
model: sonnet
---

You are the verification agent for marathon-ralph.

Your job is to ensure the codebase is healthy before new work begins:

## Detection
1. Detect project type (Node.js, Python, etc.) from package.json, pyproject.toml, etc.
2. Identify available test commands
3. Identify linter configuration
4. Identify type checker configuration

## Verification Steps
Run each check that is available:

1. **Unit Tests**
   - Node.js: `npm test` or `npm run test:unit`
   - Python: `pytest` or `python -m pytest`

2. **Integration Tests** (if present)
   - Look for `test:integration` script or `tests/integration/` directory

3. **E2E Tests** (if present)
   - Look for `test:e2e` script or Playwright/Cypress config

4. **Linting**
   - Node.js: `npm run lint`
   - Python: `ruff check .` or `flake8`

5. **Type Checking**
   - TypeScript: `npx tsc --noEmit`
   - Python: `mypy .` or `pyright`

## On Failure
If ANY check fails:
1. Create a NEW bug issue in Linear describing the failure
2. Link it to the most recently completed issue (if regression)
3. Set priority based on severity
4. Report: "Verification failed. Created issue [ID] for: [summary]"
5. The bug issue becomes the next issue to work on

## On Success
Report: "All verification checks passed. Ready for new work."

Return a structured summary:
- tests: pass/fail/skip
- lint: pass/fail/skip
- types: pass/fail/skip
- ready_for_work: true/false
- blocking_issue: [issue ID if created]
```

---

### 4. plan-agent

**File:** `agents/plan.md`

**Purpose:** Create implementation plan for current issue.

**Model:** `sonnet`

**Tools:** `Read`, `Glob`, `Grep`

**Responsibilities:**

1. Read current issue details from Linear
2. Explore relevant parts of codebase
3. Identify files that need modification
4. Create step-by-step implementation plan
5. Document assumptions as comment on Linear issue
6. Output plan for code-agent

**Prompt:**

```markdown
---
name: marathon-plan
description: Create implementation plan for the current Linear issue. Reviews codebase and documents approach.
tools: Read, Glob, Grep
model: sonnet
---

You are the planning agent for marathon-ralph.

Your job is to create a detailed implementation plan for the current issue:

## Input
You will receive the current issue ID and details.

## Planning Steps

1. **Understand Requirements**
   - Read the issue description and acceptance criteria
   - Identify what "done" looks like
   - Note any ambiguities or questions

2. **Explore Codebase**
   - Find related files using Glob and Grep
   - Understand existing patterns and conventions
   - Identify integration points

3. **Create Plan**
   Document a clear implementation plan:
   - Files to create (with proposed location)
   - Files to modify (with specific changes)
   - Order of operations
   - Testing approach

4. **Document Assumptions**
   - Add a comment to the Linear issue with:
     - Your understanding of requirements
     - Any assumptions you're making
     - Questions (if blocking, escalate to user)

## Output
Return a structured plan:
```

## Implementation Plan for [Issue Title]

### Files to Create

- path/to/new/file.ts - Purpose

### Files to Modify

- path/to/existing.ts - What changes

### Implementation Steps

1. Step one
2. Step two
...

### Testing Plan

- Unit tests: ...
- Integration tests: ...

### Assumptions

- Assumption 1
- Assumption 2

```

Do NOT implement anything. Planning only.
```

---

### 5. code-agent

**File:** `agents/code.md`

**Purpose:** Implement the feature according to plan.

**Model:** `sonnet`

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Responsibilities:**

1. Follow plan from plan-agent
2. Write clean, well-structured code
3. Follow project conventions (from CLAUDE.md)
4. Verify implementation manually (run app, check behavior)
5. Commit changes with descriptive message referencing Linear issue

**Prompt:**

```markdown
---
name: marathon-code
description: Implement the current feature following the implementation plan.
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
---

You are the implementation agent for marathon-ralph.

Your job is to implement the feature according to the provided plan:

## Guidelines

1. **Follow the Plan**
   - Implement exactly what the plan specifies
   - If you discover the plan is incomplete, note it but continue
   - Don't add features not in the plan (no scope creep)

2. **Code Quality**
   - Follow existing project conventions
   - Read CLAUDE.md for project-specific guidelines
   - Write clean, readable code
   - Add comments only where logic is non-obvious

3. **Verification**
   - After implementing, run the app to verify it works
   - Check the feature manually matches acceptance criteria
   - Fix any obvious issues before committing

4. **Commit**
   Create a commit with message format:
   ```

   feat: [Brief description]

- [Change 1]
- [Change 2]

   Linear: [ISSUE-ID]

   ```

## Output
Report:
- What was implemented
- Any deviations from plan
- Verification results
- Commit hash

Do NOT write tests. The test-agent handles that.
```

---

### 6. test-agent

**File:** `agents/test.md`

**Purpose:** Write tests for the implemented feature.

**Model:** `sonnet`

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Responsibilities:**

1. Review the implementation from code-agent
2. Review the issue requirements
3. Check existing test patterns in codebase
4. Write unit tests for new code
5. Write integration tests if applicable
6. Run tests to verify they pass
7. Commit test files

**Prompt:**

```markdown
---
name: marathon-test
description: Write unit and integration tests for the implemented feature.
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
---

You are the testing agent for marathon-ralph.

Your job is to write comprehensive tests for the recently implemented feature:

## Process

1. **Review Implementation**
   - Read the files modified in the recent commit
   - Understand what was implemented
   - Identify testable units

2. **Review Requirements**
   - Check the Linear issue for acceptance criteria
   - Each criterion should have corresponding test coverage

3. **Follow Patterns**
   - Look at existing tests for patterns
   - Use the same testing framework and conventions
   - Place tests in the appropriate directory

4. **Write Tests**
   - Unit tests for individual functions/components
   - Integration tests for feature workflows
   - Edge cases and error handling
   - Happy path and failure scenarios

5. **Verify**
   - Run the new tests: they should pass
   - Run all tests: ensure no regressions

6. **Commit**
   ```

   test: Add tests for [feature]

- [Test category 1]
- [Test category 2]

   Linear: [ISSUE-ID]

   ```

## Output
Report:
- Tests written (count and type)
- Coverage added
- All tests passing: yes/no
- Commit hash
```

---

### 7. qa-agent

**File:** `agents/qa.md`

**Purpose:** Create E2E tests for web projects.

**Model:** `sonnet`

**Tools:** `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`

**Responsibilities:**

1. Determine if project is web-based (check for browser/UI components)
2. If not web-based, skip with message
3. Review feature from user perspective
4. Create E2E tests using project's E2E framework (Playwright, Cypress, etc.)
5. Write tests in BDD/Gherkin style when appropriate
6. Run E2E tests to verify
7. Commit E2E test files

**Prompt:**

```markdown
---
name: marathon-qa
description: Create E2E tests for web features. Skips non-web projects.
tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
---

You are the QA agent for marathon-ralph.

Your job is to create end-to-end tests for web features:

## Pre-Check
1. Determine if this is a web project:
   - Look for: React, Vue, Next.js, browser-based UI
   - Check for existing E2E setup (Playwright, Cypress)
2. If NOT a web project, report "Skipping E2E: not a web project" and exit

## E2E Test Creation

1. **Review Feature**
   - Understand the user-facing behavior
   - Identify user flows to test
   - Check acceptance criteria for E2E scenarios

2. **Use Existing Framework**
   - Playwright: `tests/e2e/*.spec.ts`
   - Cypress: `cypress/e2e/*.cy.ts`
   - Follow existing patterns

3. **Write Tests**
   - Test complete user flows
   - Include setup and teardown
   - Use descriptive test names
   - Consider BDD style:
     ```
     test('user can complete checkout flow', async ({ page }) => {
       // Given: user has items in cart
       // When: user proceeds to checkout
       // Then: order is confirmed
     });
     ```

4. **Verify**
   - Run E2E tests (may need app running)
   - Fix any flaky tests

5. **Commit**
   ```

   test(e2e): Add E2E tests for [feature]

   Linear: [ISSUE-ID]

   ```

## Output
Report:
- E2E tests written (or skipped reason)
- Test scenarios covered
- All E2E passing: yes/no
- Commit hash
```

---

## Commands

### /marathon-ralph:start

**File:** `commands/start.md`

```markdown
---
description: Start autonomous marathon development from a specification file
---

# Start Marathon

Start a new marathon development session.

## Arguments
$ARGUMENTS

Expected format: `--spec-file <path>` or just `<path>`

## Process

1. Parse spec file path from arguments
2. Check if `.claude/marathon-ralph.json` exists:
   - If exists with `phase: "coding"`: Resume existing marathon
   - If exists with `phase: "complete"`: Ask if user wants to start new
   - If not exists: Start fresh

3. For new marathon:
   - Run setup-agent to verify Linear MCP
   - Run init-agent to create project and issues
   - Begin coding loop

4. For resume:
   - Run verify-agent
   - Continue with next issue

## Loop (via Stop hook)
After each issue completion:
1. verify-agent: Check codebase health
2. Query Linear for next Todo issue (by priority)
3. If no more issues: Complete marathon
4. plan-agent: Create implementation plan
5. code-agent: Implement feature
6. test-agent: Write tests
7. qa-agent: Write E2E tests (web only)
8. Update issue to Done in Linear
9. Update META issue with session notes
10. Commit all changes
11. Continue to next issue (via Stop hook)
```

### /marathon-ralph:status

**File:** `commands/status.md`

```markdown
---
description: Check marathon progress and Linear project status
---

# Marathon Status

Show current marathon status.

## Process

1. Read `.claude/marathon-ralph.json`
2. If no active marathon: Report "No active marathon"
3. Query Linear for current issue counts:
   - Done
   - In Progress
   - Todo
4. Show current issue being worked on
5. Calculate progress percentage
6. Show recent session activity from META issue

## Output Format
```

Marathon: [Project Name]
Progress: [X]/[Total] issues ([Y]%)

Status:
  Done: X
  In Progress: Y
  Todo: Z

Current Issue: [ID] - [Title]

Recent Activity:

```
```

### /marathon-ralph:cancel

**File:** `commands/cancel.md`

```markdown
---
description: Cancel the active marathon
---

# Cancel Marathon

Stop the current marathon and clean up.

## Process

1. Read `.claude/marathon-ralph.json`
2. If no active marathon: Report "No active marathon to cancel"
3. Confirm with user: "Cancel marathon [Project Name]? (y/n)"
4. If confirmed:
   - Set `active: false` in state file
   - Add final note to META issue in Linear
   - Report: "Marathon cancelled. Linear project preserved."
5. Note: Does NOT delete Linear project/issues (user can resume later)
```

---

## Skill Definition

**File:** `skills/marathon-ralph/SKILL.md`

```markdown
---
name: marathon-ralph
description: Autonomous long-running development from specifications. Use when user wants to build an application from a spec file, run continuous development, or automate feature implementation. Triggers on phrases like "marathon this", "build from spec", "autonomous development", "keep coding until done".
---

# Marathon Ralph - Autonomous Development

This skill enables autonomous, long-running development sessions that:
- Create Linear projects from specification files
- Work through issues systematically with verification
- Continue across multiple sessions via Stop hook
- Produce fully tested applications

## Triggers
Activate this skill when the user:
- Wants to build an application from a specification
- Says "marathon this [spec]" or "build from [spec]"
- Asks for autonomous/continuous development
- Wants to "keep coding until done"
- Provides a spec file and wants it implemented

## Usage

### Start New Marathon
```

/marathon-ralph:start --spec-file path/to/spec.md

```
Or naturally: "Marathon this spec.md until complete"

### Check Progress
```

/marathon-ralph:status

```
Or naturally: "How's the marathon going?"

### Cancel
```

/marathon-ralph:cancel

```
Or naturally: "Stop the marathon"

## Prerequisites
User must have Linear MCP configured:
1. `claude mcp add --transport http linear https://mcp.linear.app/mcp`
2. `/mcp` → Authenticate with Linear

## How It Works
1. **Setup**: Verifies Linear MCP connection
2. **Init**: Creates Linear project and issues from spec
3. **Loop**: For each issue:
   - Verify (tests, lint, types)
   - Plan implementation
   - Code the feature
   - Write tests
   - Write E2E tests (web)
   - Commit and mark Done
4. **Continue**: Stop hook keeps it running until all issues complete
```

---

## Hooks Configuration

**File:** `hooks/hooks.json`

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

**File:** `hooks/stop-hook.sh`

```bash
#!/bin/bash

# marathon-ralph Stop Hook
# Checks if marathon should continue or allow exit

set -e

# Read input from stdin
INPUT=$(cat)

# Extract session info
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Find project directory (where .claude/ would be)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/.claude/marathon-ralph.json"

# If no state file, allow exit (not in a marathon)
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read state
ACTIVE=$(jq -r '.active // false' "$STATE_FILE")
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE")

# If not active or complete, allow exit
if [ "$ACTIVE" != "true" ] || [ "$PHASE" = "complete" ]; then
  exit 0
fi

# If already in a stop hook loop, check iteration limit
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  # Get iteration count from state
  ITERATIONS=$(jq -r '.stop_hook_iterations // 0' "$STATE_FILE")
  MAX_ITERATIONS=100  # Safety limit

  if [ "$ITERATIONS" -ge "$MAX_ITERATIONS" ]; then
    echo '{"decision": "allow", "reason": "Max iterations reached"}' >&2
    exit 0
  fi

  # Increment iteration count
  jq ".stop_hook_iterations = $((ITERATIONS + 1))" "$STATE_FILE" > "$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE"
fi

# Marathon is active - check if there's more work
# Query Linear for remaining issues (this is a simplified check)
# The actual implementation would query Linear MCP

# For now, output JSON to block exit and continue
cat << 'EOF'
{
  "decision": "block",
  "reason": "Marathon in progress. Continue with next issue:\n\n1. Run verify-agent to check codebase health\n2. Query Linear for next Todo issue\n3. If no issues remain, update state to phase: complete\n4. Otherwise, run plan-agent → code-agent → test-agent → qa-agent\n5. Mark issue Done, commit, continue"
}
EOF
```

---

## Plugin Manifest

**File:** `.claude-plugin/plugin.json`

```json
{
  "name": "marathon-ralph",
  "version": "1.0.0",
  "description": "Autonomous long-running development with Linear project management. Creates projects from specs and works through issues systematically.",
  "author": {
    "name": "marathon-ralph contributors"
  },
  "keywords": [
    "autonomous",
    "linear",
    "development",
    "marathon",
    "continuous"
  ]
}
```

---

## Implementation Order

### Phase 1: Core Structure

1. Create plugin directory structure
2. Create `.claude-plugin/plugin.json`
3. Create `README.md` with usage instructions

### Phase 2: Commands

4. Create `commands/start.md`
2. Create `commands/status.md`
3. Create `commands/cancel.md`

### Phase 3: Agents (in dependency order)

7. Create `agents/setup.md`
2. Create `agents/init.md`
3. Create `agents/verify.md`
4. Create `agents/plan.md`
5. Create `agents/code.md`
6. Create `agents/test.md`
7. Create `agents/qa.md`

### Phase 4: Automation

14. Create `hooks/hooks.json`
2. Create `hooks/stop-hook.sh`
3. Make stop-hook.sh executable

### Phase 5: Skill

17. Create `skills/marathon-ralph/SKILL.md`

### Phase 6: Testing

18. Test with sample spec file
2. Verify Linear integration
3. Test full loop execution
4. Test cancel and resume flows

---

## Success Criteria

- [ ] Plugin loads successfully with `claude --plugin-dir ./marathon-ralph`
- [ ] `/marathon-ralph:start` creates Linear project from spec
- [ ] Issues are dynamically generated based on spec content
- [ ] Team selection works when user has multiple Linear teams
- [ ] Verification runs before each new issue
- [ ] Regressions create new linked bug issues (not reopen)
- [ ] Each agent completes its designated task
- [ ] Stop hook continues marathon until all issues Done
- [ ] `/marathon-ralph:status` shows accurate progress
- [ ] `/marathon-ralph:cancel` cleanly stops marathon
- [ ] Natural language invocation works via skill
- [ ] Greenfield projects get init.sh and CLAUDE.md
- [ ] Git commits reference Linear issue IDs
- [ ] META issue tracks session handoff notes

---

## Appendix: Linear MCP Tools Reference

The plugin expects these Linear MCP tools to be available:

- `mcp__linear__get_teams` - List available teams
- `mcp__linear__create_project` - Create new project
- `mcp__linear__create_issue` - Create issue in project
- `mcp__linear__get_issues` - Query issues by status/project
- `mcp__linear__update_issue` - Update issue status/fields
- `mcp__linear__add_comment` - Add comment to issue

Actual tool names may vary based on Linear MCP implementation. Agents should discover available tools dynamically.

---

## Appendix: Example Specification File

```markdown
# My Todo Application

## Overview
A modern todo application with user authentication, task management, and team collaboration features.

## Tech Stack
- Frontend: Next.js 14 with App Router
- Styling: Tailwind CSS
- Database: PostgreSQL with Prisma
- Auth: NextAuth.js

## Features

### Authentication
- Email/password sign up and sign in
- OAuth with Google and GitHub
- Password reset via email
- Session management

### Task Management
- Create, read, update, delete tasks
- Task properties: title, description, due date, priority, status
- Drag-and-drop reordering
- Filter and search tasks

### Team Collaboration
- Create and manage teams
- Invite members via email
- Shared task lists
- Activity feed

### User Settings
- Profile management
- Notification preferences
- Theme (light/dark mode)

## Non-Functional Requirements
- Mobile responsive design
- Accessibility (WCAG 2.1 AA)
- Page load under 2 seconds
- 90%+ test coverage
```
