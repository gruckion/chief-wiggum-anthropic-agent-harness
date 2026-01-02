#!/bin/bash

# marathon-ralph Stop Hook
# Checks if marathon should continue or allow exit
# Enables continuous autonomous operation by blocking exit when marathon is active

set -e

# Read input from stdin (JSON from Claude Code)
INPUT=$(cat)

# Get project directory from environment or default to current
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/.claude/marathon-ralph.json"

# If no state file exists, allow exit (not in a marathon)
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read marathon state using jq
ACTIVE=$(jq -r '.active // false' "$STATE_FILE" 2>/dev/null || echo "false")
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")

# If not active or phase is complete, allow exit
if [ "$ACTIVE" != "true" ] || [ "$PHASE" = "complete" ]; then
  exit 0
fi

# Check iteration safety limit to prevent infinite loops
ITERATIONS=$(jq -r '.stop_hook_iterations // 0' "$STATE_FILE" 2>/dev/null || echo "0")
MAX_ITERATIONS=100

# Validate iterations is a number
if ! [[ "$ITERATIONS" =~ ^[0-9]+$ ]]; then
  ITERATIONS=0
fi

if [ "$ITERATIONS" -ge "$MAX_ITERATIONS" ]; then
  # Safety limit reached - allow exit and notify
  cat << 'EOF'
{
  "decision": "allow",
  "reason": "Max iterations (100) reached. Marathon paused for safety. Resume with /marathon-ralph:start"
}
EOF
  exit 0
fi

# Increment iteration count in state file
NEW_ITERATIONS=$((ITERATIONS + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
jq ".stop_hook_iterations = $NEW_ITERATIONS" "$STATE_FILE" > "$TEMP_FILE" 2>/dev/null
if [ $? -eq 0 ]; then
  mv "$TEMP_FILE" "$STATE_FILE"
else
  rm -f "$TEMP_FILE"
fi

# Marathon is active in coding phase - block exit and continue
# Provide instructions for the next iteration of the marathon loop
cat << 'EOF'
{
  "decision": "block",
  "reason": "Marathon in progress. Continue with next issue:\n\n1. Run verify-agent to check codebase health\n2. Query Linear for next Todo issue in the marathon project\n3. If no issues remain, update state to phase: complete\n4. Otherwise, run plan-agent -> code-agent -> test-agent -> qa-agent\n5. Mark issue Done in Linear, commit changes, continue to next issue",
  "systemMessage": "Marathon ralph continuing to next issue..."
}
EOF

exit 0
