---
description: "Show current marathon session status"
allowed-tools: ["Bash", "Read"]
---

# Marathon Ralph Status

Check the current marathon session status:

1. Check if `.claude/marathon-ralph.json` exists using Bash: `test -f .claude/marathon-ralph.json && echo "EXISTS" || echo "NOT_FOUND"`

2. **If NOT_FOUND**: Report "No active marathon session."

3. **If EXISTS**:
   - Read `.claude/marathon-ralph.json` to get the current state
   - Display the following information:
     - **Issue**: The Linear issue identifier (e.g., `ENG-123`)
     - **Status**: Current session status (e.g., `active`, `paused`)
     - **Started**: When the marathon was started
     - **Iterations**: Current iteration count
     - **Last Activity**: Timestamp of last activity
   - Provide a brief summary of the marathon state
