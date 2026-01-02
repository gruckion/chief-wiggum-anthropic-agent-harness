# Linear-Coding-Agent-Harness

## Overview

This is an Autonomous Coding Agent Demo that implements a two-agent pattern (initializer + coding agent) with Linear as the core project management system for tracking all work.

## Project Architecture

```
Linear-Coding-Agent-Harness/
├── autonomous_agent_demo.py  # Main entry point
├── agent.py                  # Agent session logic
├── client.py                 # Claude SDK + MCP client configuration
├── security.py               # Bash command allowlist and validation
├── progress.py               # Progress tracking utilities
├── prompts.py                # Prompt loading utilities
├── linear_config.py          # Linear configuration constants
├── prompts/
│   ├── app_spec.txt          # Application specification (Claude.ai clone)
│   ├── initializer_prompt.md # First session prompt (creates Linear issues)
│   └── coding_prompt.md      # Continuation session prompt (works issues)
├── requirements.txt          # Python dependencies (claude-code-sdk>=0.0.25)
└── test_security.py          # Security hook tests
```

## Key Components

### Two-Agent Pattern

1. **Initializer Agent** (Session 1): Reads `app_spec.txt`, creates Linear project with 50 issues, sets up project structure
2. **Coding Agent** (Sessions 2+): Queries Linear for Todo issues, implements features, tests via Puppeteer, marks Done

### MCP Integration

- **Linear MCP**: Project management at `mcp.linear.app/mcp` (Streamable HTTP)
- **Puppeteer MCP**: Browser automation for UI testing

### Security Model (Defense in Depth)

- OS-level sandbox for bash commands
- Filesystem restrictions to project directory
- Bash allowlist validation (`security.py`)
- MCP permissions explicitly allowed

## Running the Demo

```bash
# Required environment variables
export CLAUDE_CODE_OAUTH_TOKEN='your-oauth-token-here'  # from `claude setup-token`
export LINEAR_API_KEY='lin_api_xxxxxxxxxxxxx'           # from Linear settings

# Install dependencies
pip install -r requirements.txt

# Run the demo
python autonomous_agent_demo.py --project-dir ./my_project

# Limit iterations for testing
python autonomous_agent_demo.py --project-dir ./my_project --max-iterations 3
```

## Development Guidelines

### Allowed Bash Commands (security.py)

- File inspection: `ls`, `cat`, `head`, `tail`, `wc`, `grep`
- File operations: `cp`, `mkdir`, `chmod` (+x only)
- Node.js: `npm`, `node`
- Git: `git`
- Process: `ps`, `lsof`, `sleep`, `pkill` (dev processes only)
- Script execution: `./init.sh` only

### Testing

Run security tests:

```bash
python test_security.py
```

### Linear Workflow

- Issues tracked with status: Todo -> In Progress -> Done
- META issue for session tracking and handoff
- Comments on issues for implementation notes

## Configuration Constants (linear_config.py)

- `DEFAULT_ISSUE_COUNT`: 50
- `STATUS_TODO`, `STATUS_IN_PROGRESS`, `STATUS_DONE`: Issue status workflow
- `LINEAR_PROJECT_MARKER`: `.linear_project.json`
- `META_ISSUE_TITLE`: `[META] Project Progress Tracker`

## Default Model

Uses Claude Opus 4.5 (`claude-opus-4-5-20251101`) by default for best coding and agentic performance.

## Generated Project Structure

After running, the project directory will contain:

```
my_project/
├── .linear_project.json      # Linear project state (marker file)
├── app_spec.txt              # Copied specification
├── init.sh                   # Environment setup script
├── .claude_settings.json     # Security settings
└── [application files]       # Generated application code
```
