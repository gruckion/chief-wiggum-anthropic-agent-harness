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

   - **If phase is "complete":**
     Ask: "Previous marathon completed. Start a new marathon? (This will overwrite the state file)"
     - If user confirms, proceed to Step 5
     - If user declines, exit

   - **If phase is "setup" or "init":**
     Report: "A marathon setup is in progress. Resuming from phase: <phase>"
     Proceed based on the phase

**If state file NOT_FOUND:**
Proceed to Step 5

### Step 5: Start New Marathon

1. **Run setup-agent** to verify Linear MCP is connected:

   Use the Agent tool to run `marathon-setup`:
   - The setup agent will check Linear MCP connectivity
   - It will create `.claude/marathon-ralph.json` with `phase: "setup"`
   - It will report success or failure with next steps

2. **If setup succeeds:**

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

3. **Report Status:**
   ```
   Marathon Setup Started

   Spec File: <spec_path>
   Phase: setup
   State File: .claude/marathon-ralph.json

   Linear MCP verified. Ready to proceed with initialization.

   Next step: Run /marathon-ralph:init to create Linear project and issues.
   ```

### Error Handling

- If spec file not provided: Request spec file path
- If spec file not found: Report file not found error
- If Linear MCP not connected: setup-agent will provide instructions
- If authentication fails: setup-agent will provide re-auth instructions

## Notes

- The spec file should be a markdown file describing the project requirements
- This command only handles setup verification in this version
- Full initialization (creating Linear issues) will be added in Group 3
