---
description: Start autonomous marathon development from a specification file
argument-hint: --spec-file <path> or just <path>
allowed-tools: ["Read", "Write", "Bash", "Glob", "Agent"]
---

# Start Marathon

Start a new marathon development session from a specification file, or resume an existing session.

## Arguments

$ARGUMENTS

Expected formats:
- `--spec-file <path>`
- `<path>` (direct path to spec file)

## Process

### Step 1: Parse Spec File Path

Extract the spec file path from the arguments:
- If argument starts with `--spec-file`, use the following value
- Otherwise, treat the entire argument as the path
- If no path provided, report error: "Please provide a spec file path: /marathon-ralph:start --spec-file <path>"

### Step 2: Validate Spec File Exists

Use Bash to check if the spec file exists:
```bash
test -f "<spec_path>" && echo "EXISTS" || echo "NOT_FOUND"
```

If NOT_FOUND, report error: "Spec file not found: <spec_path>"

### Step 3: Check Existing Marathon State

Check if `.claude/marathon-ralph.json` exists:
```bash
test -f .claude/marathon-ralph.json && echo "EXISTS" || echo "NOT_FOUND"
```

### Step 4: Handle Existing State

**If state file EXISTS:**

1. Read `.claude/marathon-ralph.json`
2. Check the `phase` field:

   - **If phase is "coding":**
     Report: "An active marathon is in progress. Resuming coding loop..."
     Skip to Step 8 (Coding Loop).

   - **If phase is "complete":**
     Ask: "Previous marathon completed. Start a new marathon? (This will overwrite the state file)"
     - If user confirms, proceed to Step 5
     - If user declines, exit

   - **If phase is "setup":**
     Report: "A marathon setup is in progress. Resuming from setup phase..."
     Skip to Step 6 (run init-agent)

   - **If phase is "init":**
     Report: "A marathon initialization is in progress. Resuming..."
     Skip to Step 6 (run init-agent)

**If state file NOT_FOUND:**
Proceed to Step 5

### Step 5: Run Setup Agent

1. **Run setup-agent** to verify Linear MCP is connected:

   Use the Agent tool to run `marathon-setup`:
   - The setup agent will check Linear MCP connectivity
   - It will create `.claude/marathon-ralph.json` with `phase: "setup"`
   - It will report success or failure with next steps

2. **If setup fails:**
   Report the failure and provide instructions from the setup agent.
   Exit - do not proceed.

3. **If setup succeeds:**
   Update the state file to include the spec file path:
   ```json
   {
     "active": true,
     "phase": "setup",
     "spec_file": "<absolute_path_to_spec>",
     "created_at": "<timestamp>",
     "last_updated": "<timestamp>"
   }
   ```

### Step 6: Run Init Agent

1. **Update phase to "init":**
   ```json
   {
     "active": true,
     "phase": "init",
     "spec_file": "<absolute_path_to_spec>",
     ...
   }
   ```

2. **Run init-agent** to create Linear project and issues:

   Use the Agent tool to run `marathon-init`:
   - Pass the spec file path as context
   - The init agent will:
     - Read and analyze the specification
     - Query Linear for teams (may ask user to choose)
     - Create Linear project
     - Create all issues from the spec
     - Create META issue for tracking
     - Handle greenfield project setup if needed
     - Update state file with Linear metadata and phase: "coding"

3. **If init fails:**
   Report the failure with context.
   The state remains at phase: "init" for retry.

4. **If init succeeds:**
   The init-agent will have updated the state to phase: "coding".
   Proceed to Step 7.

### Step 7: Report Initialization Complete

```
Marathon Initialized Successfully

Spec File: <spec_path>
Phase: coding
Linear Project: <project_name>
Total Issues: <issue_count>

Starting coding loop...
```

Proceed to Step 8.

### Step 8: Run Coding Loop

The coding loop works on one issue at a time. Currently, it processes ONE issue per invocation (hooks in Group 6 will enable automatic continuation).

#### 8.1: Run Verification Agent

**Run verify-agent** to check codebase health:

Use the Agent tool to run `marathon-verify`:
- The agent runs tests, lint, and type checks
- Returns status: pass/fail and details

**If verification fails:**
- The verify-agent creates a bug issue in Linear
- Report: "Verification failed. Bug issue created: [ID]. This must be fixed before new work."
- Set `current_issue` in state to the bug issue
- Proceed to step 8.3 (plan the fix)

**If verification passes:**
- Report: "Verification passed. Fetching next issue..."
- Proceed to step 8.2

#### 8.2: Get Next Issue from Linear

Query Linear for the next Todo issue to work on:

1. **Query Linear** for issues in the project with status "Todo"
2. **Sort by priority** (P0 > P1 > P2 > P3, then by creation date)
3. **Select the first issue** (highest priority, oldest)

**If no issues remain (all done or in other states):**
- Update state file:
  ```json
  {
    "active": false,
    "phase": "complete",
    ...
  }
  ```
- Report:
  ```
  Marathon Complete!

  All issues have been processed.

  Summary:
  - Total issues: <count>
  - Completed: <completed_count>

  The marathon is finished.
  ```
- Exit - marathon is complete.

**If issue found:**
- Mark the issue as "In Progress" in Linear
- Update state file with current_issue:
  ```json
  {
    "current_issue": {
      "id": "<issue_id>",
      "title": "<issue_title>"
    },
    "last_updated": "<timestamp>"
  }
  ```
- Proceed to step 8.3

#### 8.3: Run Plan Agent

**Run plan-agent** for the current issue:

Use the Agent tool to run `marathon-plan`:
- Pass the current issue ID and details
- The agent explores the codebase
- Returns an implementation plan

Store the plan for the code agent.

#### 8.4: Run Code Agent

**Run code-agent** to implement the feature:

Use the Agent tool to run `marathon-code`:
- Pass the implementation plan
- Pass the current issue details
- The agent implements the feature
- Creates a commit

**If implementation fails:**
- Report the failure
- Keep issue as "In Progress" for retry
- Exit (user can retry by running /marathon-ralph:start again)

**If implementation succeeds:**
- Mark the issue as "Done" in Linear
- Update stats in state file:
  ```json
  {
    "stats": {
      "completed": <incremented>,
      "in_progress": 0,
      "todo": <decremented>
    }
  }
  ```

#### 8.5: Update META Issue

Add a session note to the META issue in Linear:

```markdown
## Session Update - <timestamp>

### Issue Completed
- [ISSUE-ID] <title>

### Changes Made
- <commit message summary>

### Notes
- <any relevant notes>
```

#### 8.6: Report Progress

```
Issue Completed: [ISSUE-ID] <title>

Commit: <hash>
Changes: <summary>

Progress: <completed>/<total> issues done

Note: Run /marathon-ralph:start again to continue with the next issue,
or the Stop hook will continue automatically in future sessions.
```

**Note:** Currently the loop stops after ONE issue. In Group 6, hooks will enable automatic continuation.

## Error Handling

- If spec file not provided: Request spec file path
- If spec file not found: Report file not found error
- If Linear MCP not connected: setup-agent will provide instructions
- If authentication fails: setup-agent will provide re-auth instructions
- If Linear project creation fails: init-agent will report the issue
- If verification fails: Bug issue created, becomes next task
- If implementation fails: Report failure, user can retry

## Resume Behavior

When resuming from an interrupted session:

| Current Phase | Action |
|---------------|--------|
| setup | Re-run setup-agent, then init-agent, then coding loop |
| init | Re-run init-agent, then coding loop |
| coding | Resume coding loop (verify → get issue → plan → code) |
| complete | Ask user confirmation to start new marathon |

## State File Updates

The state file is updated at these points:
- After setup: phase: "setup", spec_file added
- After init: phase: "coding", linear metadata added
- When starting issue: current_issue set, in_progress incremented
- When completing issue: current_issue cleared, completed incremented
- When all done: phase: "complete", active: false

## Notes

- The spec file should be a markdown file describing the project requirements
- This command orchestrates the full flow: setup → init → coding loop
- One issue is processed per invocation (automatic continuation comes in Group 6)
- All Linear project/issue creation happens in the init-agent
- The verify-agent ensures code health before each new issue
- The plan-agent creates implementation plans
- The code-agent writes the actual code
