---
description: Check marathon progress and Linear project status
allowed-tools: ["Bash", "Read"]
---

# Marathon Ralph Status

Check the current marathon session status.

## Process

### Step 1: Check State File Exists

```bash
test -f .claude/marathon-ralph.json && echo "EXISTS" || echo "NOT_FOUND"
```

### Step 2: Handle NOT_FOUND

If the state file does not exist, report:

```
Marathon Ralph Status
---------------------
No active marathon session.

To start a new marathon:
  /marathon-ralph:start --spec-file <path-to-spec.md>
```

### Step 3: Handle EXISTS

Read `.claude/marathon-ralph.json` and display status based on the `phase` field.

#### Phase: setup

```
Marathon Ralph Status
---------------------
Phase: Setup
Status: Verifying environment

Spec File: <spec_file if present>
Started: <created_at>
Last Updated: <last_updated>

Environment setup in progress. Linear MCP being verified.
```

#### Phase: init

```
Marathon Ralph Status
---------------------
Phase: Initialization
Status: Creating Linear project

Spec File: <spec_file>
Started: <created_at>
Last Updated: <last_updated>

Linear project and issues are being created from the specification.
```

#### Phase: coding

```
Marathon Ralph Status
---------------------
Phase: Coding
Status: Active Development

Spec File: <spec_file>
Linear Project: <linear.project_name> (<linear.team_name>)
Meta Issue: <linear.meta_issue_id>

Current Issue: <current_issue.id> - <current_issue.title>

Progress:
  Completed: <stats.completed>/<linear.total_issues>
  In Progress: <stats.in_progress>
  Todo: <stats.todo>

Started: <created_at>
Last Updated: <last_updated>
```

#### Phase: complete

```
Marathon Ralph Status
---------------------
Phase: Complete
Status: Marathon Finished

Spec File: <spec_file>
Linear Project: <linear.project_name> (<linear.team_name>)
Meta Issue: <linear.meta_issue_id>

Final Stats:
  Total Issues: <linear.total_issues>
  Completed: <stats.completed>

Started: <created_at>
Completed: <last_updated>

To start a new marathon:
  /marathon-ralph:start --spec-file <path-to-spec.md>
```

### Step 4: Handle Partial State

If any expected fields are missing, show what is available and note missing information:

```
Marathon Ralph Status
---------------------
Phase: <phase>
Status: <active ? "Active" : "Inactive">

<Available fields...>

Note: Some state information is incomplete.
```

## State File Schema Reference

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
