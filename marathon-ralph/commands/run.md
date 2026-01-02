---
description: Run autonomous marathon development - resume existing or start new from specification
argument-hint: [--spec-file <path> | <path>] (only required when starting new)
allowed-tools: ["Read", "Write", "Bash", "Glob", "Agent"]
---

# Run Marathon

Run the marathon development system. This command automatically:

- **Resumes** an existing marathon if one is in progress (no arguments needed)
- **Starts** a new marathon from a specification file (spec file required)

## Arguments

$ARGUMENTS

Expected formats (only required when starting new):

- `--spec-file <path>`
- `<path>` (direct path to spec file)
- No arguments (resume existing marathon)

## Process

### Step 1: Check Existing Marathon State

Use the Read tool to check if `.claude/marathon-ralph.json` exists:

- Attempt to read the file
- If successful, the file exists - proceed to parse the JSON
- If the Read tool returns an error (file not found), treat as NOT_FOUND

### Step 2: Handle Based on State

**If state file EXISTS:**

1. Read `.claude/marathon-ralph.json`
2. Check the `phase` field:

   - **If phase is "coding":**
     Report: "Resuming active marathon..."
     Display current progress (X/Y issues completed)
     Skip to Step 7 (Coding Loop) - NO spec file needed.

   - **If phase is "setup":**
     Report: "Resuming marathon from setup phase..."
     Skip to Step 5 (Run Init Agent) - spec file already in state.

   - **If phase is "init":**
     Report: "Resuming marathon initialization..."
     Skip to Step 5 (Run Init Agent) - spec file already in state.

   - **If phase is "complete":**
     Report: "Previous marathon completed."
     Check if spec file argument was provided:
     - If YES: Ask "Start a new marathon with this spec? (This will overwrite the previous state)"
       - If confirmed, proceed to Step 3
       - If declined, exit
     - If NO: Report "Run with a spec file to start a new marathon: /marathon-ralph:run <spec-file>"
       Exit.

**If state file NOT_FOUND:**

Check if spec file argument was provided:

- If YES: Proceed to Step 3
- If NO: Report error:

  ```markdown
  No active marathon found.

  To start a new marathon, provide a specification file:
    /marathon-ralph:run <spec-file>
    /marathon-ralph:run --spec-file path/to/spec.md
  ```

  Exit.

### Step 3: Parse Spec File Path

Extract the spec file path from the arguments:

- If argument starts with `--spec-file`, use the following value
- Otherwise, treat the entire argument as the path

### Step 4: Locate and Validate Spec File

Use Glob with pattern `**/<spec_path>` to find the file.

- If multiple matches, ask user to choose
- If none found, report error with helpful message

Then run the setup agent:

1. **Run setup-agent** to verify Linear MCP is connected:

   Use the Agent tool to run `marathon-setup`:

   - The setup agent will check Linear MCP connectivity
   - It will create `.claude/marathon-ralph.json` with `phase: "setup"`
   - It will report success or failure with next steps

2. **If setup fails:**
   Report the failure and provide instructions from the setup agent.
   Exit - do not proceed.

3. **If setup succeeds:**
   Update the state file to include the spec file path and session ID:

   ```json
   {
     "active": true,
     "phase": "setup",
     "spec_file": "<absolute_path_to_spec>",
     "session_id": "<current_session_id>",
     "created_at": "<timestamp>",
     "last_updated": "<timestamp>"
   }
   ```

   **IMPORTANT:** The `session_id` enables session-scoped operation. The Stop hook only blocks exit for the session that started the marathon. Other sessions working in the same directory will not be affected.

### Step 5: Run Init Agent

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
   Proceed to Step 6.

### Step 6: Report Initialization Complete

```markdown
Marathon Initialized Successfully

Spec File: <spec_path>
Phase: coding
Linear Project: <project_name>
Total Issues: <issue_count>

Starting coding loop...
```

Proceed to Step 7.

### Step 7: Run Coding Loop

The coding loop works on one issue at a time. Currently, it processes ONE issue per invocation (hooks in Group 6 will enable automatic continuation).

#### 7.1: Run Verification Agent

**Run verify-agent** to check codebase health:

Use the Agent tool to run `marathon-verify`:

- The agent runs tests, lint, and type checks
- Returns status: pass/fail and details

**If verification fails:**

- The verify-agent creates a bug issue in Linear
- Report: "Verification failed. Bug issue created: [ID]. This must be fixed before new work."
- Set `current_issue` in state to the bug issue
- Proceed to step 7.3 (plan the fix)

**If verification passes:**

- Report: "Verification passed. Fetching next issue..."
- Proceed to step 7.2

#### 7.2: Get Next Issue from Linear

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

  ```markdown
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

- Proceed to step 7.3

#### 7.3: Run Plan Agent

**Run plan-agent** for the current issue:

Use the Agent tool to run `marathon-plan`:

- Pass the current issue ID and details
- The agent explores the codebase
- Returns an implementation plan

Store the plan for the code agent.

#### 7.4: Run Code Agent

**Run code-agent** to implement the feature:

Use the Agent tool to run `marathon-code`:

- Pass the implementation plan
- Pass the current issue details
- The agent implements the feature
- Creates a commit

**If implementation fails:**

- Report the failure
- Keep issue as "In Progress" for retry
- Exit (user can retry by running /marathon-ralph:run again)

**If implementation succeeds:**

- Proceed to step 7.5 (test-agent)

#### 7.5: Run Test Agent

**Run test-agent** to write tests for the implementation:

Use the Agent tool to run `marathon-test`:

- The agent reviews the implementation from code-agent
- Writes unit tests for new code
- Writes integration tests if applicable
- Creates a commit with the tests

**If test writing fails:**

- Report the failure
- Keep issue as "In Progress" for retry
- Exit (user can retry)

**If tests pass:**

- Proceed to step 7.6 (qa-agent)

#### 7.6: Run QA Agent

**Run qa-agent** to create E2E tests (for web projects):

Use the Agent tool to run `marathon-qa`:

- The agent checks if this is a web project
- If not a web project: Skips with message and proceeds
- If web project: Creates E2E tests for the feature
- Creates a commit with E2E tests (if applicable)

**If E2E tests fail:**

- Report the failure
- Keep issue as "In Progress" for retry
- Exit (user can retry)

**If E2E tests pass (or skipped for non-web):**

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

#### 7.7: Update META Issue

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

#### 7.8: Report Progress

```markdown
Issue Completed: [ISSUE-ID] <title>

Commits:
- Implementation: <hash>
- Tests: <hash>
- E2E: <hash> (or "skipped - not a web project")

Progress: <completed>/<total> issues done

Note: Run /marathon-ralph:run again to continue with the next issue,
or the Stop hook will continue automatically.
```

**Note:** Currently the loop stops after ONE issue. The Stop hook enables automatic continuation.

## Error Handling

- If no marathon and no spec file: Explain how to start
- If spec file not found: Search by filename, ask user if multiple matches
- If Linear MCP not connected: setup-agent will provide instructions
- If authentication fails: setup-agent will provide re-auth instructions
- If Linear project creation fails: init-agent will report the issue
- If verification fails: Bug issue created, becomes next task
- If implementation fails: Report failure, user can retry
- If test writing fails: Report failure, keep issue In Progress
- If E2E tests fail: Report failure, keep issue In Progress

## Resume Behavior

| Current Phase | Action                                                         | Spec Required? |
| ------------- | -------------------------------------------------------------- | -------------- |
| coding        | Resume coding loop (verify -> get issue -> plan -> code -> test -> qa) | No             |
| setup         | Re-run init-agent, then coding loop                            | No (in state)  |
| init          | Re-run init-agent, then coding loop                            | No (in state)  |
| complete      | Ask to start new marathon                                      | Yes            |
| (no state)    | Start fresh marathon                                           | Yes            |

## State File Updates

The state file is updated at these points:

- After setup: phase: "setup", spec_file added, session_id added
- After init: phase: "coding", linear metadata added
- When starting issue: current_issue set, in_progress incremented
- When completing issue: current_issue cleared, completed incremented
- When all done: phase: "complete", active: false

## Session Scoping

The `session_id` field in the state file enables session-scoped marathons:

- When a marathon starts, the current session's ID is stored in the state file
- The Stop hook only blocks exit for the session that started the marathon
- Other Claude sessions working in the same directory are NOT affected
- This prevents cross-session interference when running multiple sessions

## Notes

- The spec file is only required when starting a new marathon
- Resuming an existing marathon requires no arguments
- This command orchestrates the full flow: setup -> init -> coding loop
- One issue is processed per invocation (Stop hook enables continuation)
- All Linear project/issue creation happens in the init-agent
- The verify-agent ensures code health before each new issue
- The plan-agent creates implementation plans
- The code-agent writes the actual code
- The test-agent writes unit and integration tests after implementation
- The qa-agent writes E2E tests for web projects (skips non-web projects)
- Issues are only marked Done after all tests pass
