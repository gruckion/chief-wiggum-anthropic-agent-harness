# marathon-ralph Plugin - Implementation Plan

## Executive Summary

Create **marathon-ralph**, a new Claude Code plugin that combines Chief Wiggum's plugin architecture with Linear Agent's robust long-running autonomous capabilities. Inspired by Anthropic's "Effective harnesses for long-running agents" guide.

**Plugin Name: `marathon-ralph`** - Emphasizes endurance + Ralph Wiggum heritage

---

## Understanding Summary

### Linear Agent (Python + Claude SDK)

- **Architecture**: External Python harness calling Claude SDK
- **Two-Phase**: Initializer Agent (Session 1) creates 50 Linear issues, Coding Agent (Sessions 2+) works them
- **State**: Linear API as single source of truth, `.linear_project.json` for bootstrapping
- **Sessions**: Fresh context each session, auto-continues with 3-second delay
- **Verification**: Mandatory regression testing before new work
- **Git**: Commits after each feature implementation
- **Key Files**: `agent.py`, `client.py`, `prompts/initializer_prompt.md`, `prompts/coding_prompt.md`

### Chief Wiggum (Claude Code Plugin)

- **Architecture**: Plugin with Stop Hook intercepting session exit
- **Single-Phase**: Same prompt fed repeatedly in same session
- **State**: Local `.claude/wiggum-loop.local.md` file
- **Sessions**: Single continuous session (accumulates context)
- **No Verification**: No built-in regression testing
- **No Task Management**: Single prompt, no issue tracking
- **Key Files**: `hooks/stop-hook.sh`, `scripts/setup-wiggum-loop.sh`, `commands/wiggum-loop.md`

### Critical Differences

| Aspect | Linear Agent | Chief Wiggum |
|--------|--------------|--------------|
| Session Model | Multi-session (fresh context) | Single session (accumulated) |
| State Storage | Linear API (external) | Local file (session-bound) |
| Task Tracking | 50+ Linear issues | Single prompt |
| Verification | Explicit regression tests | None |
| Initialization | Separate init phase | None |
| Continuation | Clean handoffs via META issue | No handoff mechanism |

---

## Implementation Plan

### Phase 1: Create New Plugin Structure

Create new plugin `marathon-ralph` with Linear Agent capabilities:

```
marathon-ralph/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── commands/
│   ├── init.md                 # Initialize project with Linear issues
│   ├── continue.md             # Continue working on next issue
│   ├── status.md               # Show Linear project status
│   └── cancel.md               # Cancel current work
├── hooks/
│   ├── hooks.json
│   └── stop-hook.sh            # Adapted stop hook with Linear integration
├── scripts/
│   ├── init-project.sh         # Create Linear project + issues from spec
│   ├── continue-work.sh        # Pick next issue, verify, work
│   └── verify-state.sh         # Run verification tests
├── skills/
│   └── harness-loop.md         # Natural language invocation
├── prompts/
│   ├── initializer_prompt.md   # Adapted from Linear Agent
│   └── coding_prompt.md        # Adapted from Linear Agent
├── .env.example                # Template for LINEAR_API_KEY, LINEAR_TEAM_ID
└── README.md
```

### Natural Language Skill Support

The skill file will recognize patterns like:

- "Build this using spec.md" → `/marathon-init spec.md`
- "Continue working on the project" → `/marathon-continue`
- "Keep working until all tests pass" → `/marathon-continue --until "tests pass"`
- "Initialize from requirements.txt" → `/marathon-init requirements.txt`
- "Marathon this spec" → triggers init flow
- "Check project status" → `/marathon-status`
- "Run a marathon on app-spec.md" → `/marathon-init app-spec.md`

### Phase 2: Port Linear MCP Integration

**Files to create:**

- `hooks/stop-hook.sh` - Enhanced to query Linear for completion status
- `scripts/linear-utils.sh` - Shell utilities for Linear MCP calls

**Key adaptations:**

1. Use Linear MCP tools (available in Claude Code environment)
2. Store `project_id`, `team_id`, `meta_issue_id` in `.claude/ew-state.json`
3. Query Linear for issue status instead of using completion promises

### Phase 3: Implement Two-Phase Approach

**Initialization Phase (`/marathon-init <spec-file>`):**

1. Parse spec file path from user command (natural language)
2. Read spec file contents
3. Check for LINEAR_TEAM_ID in .env (prompt if missing)
4. Create Linear project via `mcp__linear__create_project`
5. Create 50 issues via `mcp__linear__create_issue` from spec
6. Create META issue for session tracking
7. Create `init.sh` setup script based on tech stack in spec
8. Initialize git repository
9. Save `.claude/harness-state.json` with project metadata:

   ```json
   {
     "initialized": true,
     "spec_file": "spec.md",
     "team_id": "TEAM-123",
     "project_id": "PROJ-456",
     "meta_issue_id": "LIN-1",
     "total_issues": 50,
     "created_at": "2025-01-02T..."
   }
   ```

10. Create `.linear_project.json` marker (compatible with Linear Agent)
11. Optionally begin first issue if prompt includes "--start"

**Continuation Phase (`/marathon-continue`):**

1. Read `.claude/harness-state.json` to get project context
2. Query Linear for progress: count Done, In Progress, Todo
3. Query Linear for META issue, read previous session notes
4. Calculate progress percentage
5. **Pre-Work Verification** (MANDATORY):
   - Query Linear for 1-2 "Done" issues
   - Test them via Puppeteer or test suite
   - If regression found → reopen issue, fix first
6. Query Linear for next Todo issue (sorted by priority)
7. Set issue to "In Progress" via `mcp__linear__update_issue`
8. Work on feature using coding_prompt.md guidance
9. Verify implementation (browser test or test suite)
10. Commit to git with descriptive message
11. Update issue to "Done" with implementation comment
12. **Session Pacing Check**:
    - If early phase (< 20%): can continue to next issue
    - If mid/late phase (> 20%): consider ending session
    - If good stopping point: update META issue and exit cleanly
13. Loop continues or exits based on pacing

### Phase 4: Context-Aware Session Management

**Problem**: Chief Wiggum accumulates context in one session; Linear Agent uses fresh sessions.

**Solution**: Hybrid approach using stop hook with context reset trigger:

```bash
# In stop-hook.sh
# After completing 1-2 issues (configurable), signal for session restart
if [[ $ISSUES_COMPLETED_THIS_SESSION -ge $MAX_ISSUES_PER_SESSION ]]; then
  # Allow exit, next invocation will be fresh session
  echo '{"decision": "allow", "reason": "Session pacing: completed max issues"}'
else
  # Continue in same session
  echo '{"decision": "block", "reason": "[continue prompt]"}'
fi
```

### Phase 5: State Verification

Port verification logic from `coding_prompt.md`:

1. Query Linear for 1-2 "Done" issues
2. Test them via Puppeteer (if available) or manual check
3. If regressions found:
   - Update issue status back to "In Progress"
   - Add comment explaining regression
   - Fix before proceeding

### Phase 6: Git Workflow Integration

Add git commit automation to stop hook:

```bash
# After each completed issue
git add .
git commit -m "Implement: $ISSUE_TITLE

- Changes: [summary from Linear comment]
- Linear issue: $ISSUE_ID
- Enhanced Wiggum session: $SESSION_NUM"
```

---

## Critical Files to Create/Modify

### New Files (create in `marathon-ralph/`)

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin metadata |
| `commands/marathon-init.md` | `/marathon-init` command for initialization |
| `commands/marathon-continue.md` | `/marathon-continue` command for continuation |
| `commands/marathon-status.md` | `/marathon-status` to show Linear progress |
| `hooks/stop-hook.sh` | Enhanced stop hook with Linear + git |
| `scripts/init-project.sh` | Initialization logic |
| `scripts/continue-work.sh` | Continuation logic |
| `prompts/initializer_prompt.md` | Adapted from Linear Agent |
| `prompts/coding_prompt.md` | Adapted from Linear Agent |

### Existing Files (reference only)

| File | Use |
|------|-----|
| `Linear-Coding-Agent-Harness/prompts/initializer_prompt.md` | Template for init prompt |
| `Linear-Coding-Agent-Harness/prompts/coding_prompt.md` | Template for coding prompt |
| `chief-wiggum/hooks/stop-hook.sh` | Template for stop hook structure |

---

## Key Design Decisions

### 1. Session Model: Multi-Session via Stop Hook

- Stop hook allows 1-2 issues per session
- After completing max issues, allows normal exit
- User runs `/marathon-continue` to start fresh session with new context
- State persists in Linear (not local files that disappear)

### 2. Task Management: Linear as Source of Truth

- All issues tracked in Linear
- `.claude/harness-state.json` stores only project IDs (bootstrap data)
- Agent queries Linear for current status, not local files

### 3. Verification: Pre-Work Testing

- Before new work, verify 1-2 completed features
- Use Puppeteer MCP if available
- Regression detection → reopen issue

### 4. Completion Detection: Issue-Based

- No completion promises; instead, check Linear:
  - All issues "Done" → project complete
  - Issues remaining → continue work

### 5. Handoff: META Issue Comments

- Each session ends with summary comment on META issue
- Next session reads META issue for context

---

## Resolved Design Decisions

### App Spec Location

- **User provides in natural language** - no hardcoded filename
- Works like Ralph Wiggum: "Marathon this spec.md until all tests pass"
- Plugin extracts spec file path from user's natural language command
- Supports natural invocations like:
  - "Build this using requirements.md as the spec"
  - "Initialize project from spec.txt"
  - "Use feature-spec.md as the blueprint"

### Linear Team Selection

- **Prompt user on first run, store in `.env`**
- Plugin checks for `LINEAR_TEAM_ID` in `.env`
- If not found, queries Linear for available teams
- Presents list and asks user to select
- Saves selection to `.env` for future runs

### Session Pacing (Dynamic - from Linear Agent)

Based on Linear Agent's proven approach:

- **Early phase (< 20% Done)**: Multiple issues per session (infrastructure setup)
- **Mid/Late phase (> 20% Done)**: 1-2 issues per session
- Agent uses judgment: "Is app stable? Good stopping point? Been working a while?"
- Commit before continuing to next issue
- Clean exit when pacing threshold reached

### Verification Testing

- Use Puppeteer MCP if available for browser testing
- Fall back to running project's test suite (npm test, etc.)
- Manual confirmation as last resort
- Test 1-2 completed features before new work

---

## Implementation Order

1. Create plugin skeleton with basic structure
2. Implement `/marathon-init` command with Linear integration
3. Implement `/marathon-continue` command with work loop
4. Enhance stop hook with issue tracking
5. Add verification logic
6. Add git automation
7. Add `/marathon-status` command
8. Test full workflow
9. Document usage

---

## Success Criteria

- [ ] Plugin accepts spec file via natural language (e.g., "init from spec.md")
- [ ] Plugin creates Linear project from user-specified spec file
- [ ] Plugin prompts for Linear team on first run, stores in .env
- [ ] Plugin creates 50 issues with detailed test steps and priorities
- [ ] Plugin creates META issue for session tracking
- [ ] Plugin continues work across multiple sessions via stop hook
- [ ] Each session picks next Todo issue by priority
- [ ] Verification runs before new work (mandatory regression testing)
- [ ] Dynamic session pacing: multiple issues early, 1-2 issues mid/late
- [ ] Git commits after each completed issue with Linear issue reference
- [ ] META issue tracks session handoffs with detailed summaries
- [ ] Plugin can run for 24+ hours with periodic session restarts
- [ ] Plugin works with natural language invocation like ralph-wiggum
- [ ] Compatible with Linear Agent's .linear_project.json marker format
