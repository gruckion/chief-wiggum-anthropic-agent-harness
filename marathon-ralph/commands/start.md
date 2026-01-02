---
description: Start autonomous marathon development from a specification file
argument-hint: --spec-file <path> or just <path>
allowed-tools: ["Read", "Write", "Bash", "Glob", "Agent"]
---

# Start Marathon

Start a new marathon development session from a specification file.

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
     Report: "An active marathon is in progress. Use /marathon-ralph:status to see current state, or delete .claude/marathon-ralph.json to start fresh."
     Exit - do not proceed further.

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

### Step 7: Report Completion

```
Marathon Started Successfully

Spec File: <spec_path>
Phase: coding
Linear Project: <project_name>
Total Issues: <issue_count>

The marathon is ready. Issues have been created in Linear.

To check progress: /marathon-ralph:status
To begin coding: The Stop hook will guide the development loop.
```

## Error Handling

- If spec file not provided: Request spec file path
- If spec file not found: Report file not found error
- If Linear MCP not connected: setup-agent will provide instructions
- If authentication fails: setup-agent will provide re-auth instructions
- If Linear project creation fails: init-agent will report the issue
- If an active marathon exists: Refuse to overwrite, suggest using status or deleting state

## Resume Behavior

When resuming from an interrupted session:

| Current Phase | Action |
|---------------|--------|
| setup | Re-run setup-agent, then init-agent |
| init | Re-run init-agent (it will check existing Linear state) |
| coding | Refuse to start new marathon (user must use status or delete state) |
| complete | Ask user confirmation to start new marathon |

## Notes

- The spec file should be a markdown file describing the project requirements
- This command orchestrates the flow: setup → init → ready for coding
- The actual coding loop is handled by the Stop hook after initialization
- All Linear project/issue creation happens in the init-agent
