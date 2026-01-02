# Chief Wiggum Plugin

This is a Claude Code plugin that implements the "Ralph Wiggum" technique for self-referential AI development loops.

## Project Overview

Chief Wiggum is a fork of the [ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) plugin, enabling iterative development by running Claude in a while-true loop with the same prompt until task completion.

### Core Concept

Feed Claude the same prompt repeatedly. Each iteration, Claude sees its previous work in files and git history, allowing iterative improvement until the task is complete.

## Directory Structure

```
chief-wiggum/
├── .claude-plugin/       # Plugin metadata
│   ├── plugin.json       # Plugin name, version, description
│   └── marketplace.json  # Marketplace listing info
├── assets/               # Plugin assets (banner image)
├── commands/             # Slash command definitions
│   ├── wiggum-loop.md    # /wiggum-loop command
│   ├── cancel-wiggum.md  # /cancel-wiggum command
│   └── help.md           # /help command
├── hooks/                # Claude Code hooks
│   ├── hooks.json        # Hook configuration
│   └── stop-hook.sh      # Stop hook that intercepts exit
├── scripts/              # Setup and utility scripts
│   └── setup-wiggum-loop.sh  # Loop initialization script
├── skills/               # Natural language skill definitions
│   └── wiggum-loop.md    # Skill for natural invocation
└── README.md             # User documentation
```

## Key Components

### Stop Hook (`hooks/stop-hook.sh`)

The core mechanism. When Claude tries to exit:

1. Checks for active loop state in `.claude/wiggum-loop.local.md`
2. Extracts the last assistant message from transcript
3. Checks for completion promise in `<promise>` tags
4. Either allows exit (complete) or blocks and feeds prompt back (continue)

### State File (`.claude/wiggum-loop.local.md`)

Created in the working directory when a loop starts. Uses markdown with YAML frontmatter:

- `active`: boolean
- `iteration`: current iteration count
- `max_iterations`: limit (0 = unlimited)
- `completion_promise`: text that signals completion
- Body contains the prompt

### Commands

- `/wiggum-loop "<prompt>" --completion-promise "<text>" --max-iterations <n>`
- `/cancel-wiggum` - Remove state file to stop loop

## Development Guidelines

### Shell Scripts

- Use `set -euo pipefail` for safety
- Handle edge cases (missing files, corrupted state)
- Provide clear error messages with context
- Use portable commands (macOS and Linux compatible)

### Completion Promise Detection

- Uses Perl for multiline regex support
- Extracts text from `<promise>` tags
- Uses literal string comparison (not glob pattern matching)

### State File Parsing

- YAML frontmatter between `---` markers
- Prompt text after second `---`
- Handle special characters in completion promises

## Testing

When making changes:

1. Test loop start: `/wiggum-loop "test" --completion-promise "DONE" --max-iterations 3`
2. Test completion detection: Output `<promise>DONE</promise>`
3. Test iteration increment: Check `.claude/wiggum-loop.local.md`
4. Test max iterations: Let loop run to limit
5. Test cancel: `/cancel-wiggum`

## Common Issues

1. **Loop runs forever**: Ensure both `--completion-promise` and `--max-iterations` are set
2. **Promise not detected**: Check exact text match, use `<promise>` tags
3. **State file corruption**: Delete `.claude/wiggum-loop.local.md` and restart

## Related Resources

- Original technique: <https://ghuntley.com/ralph/>
- Official plugin: <https://github.com/anthropics/claude-code-plugins/tree/main/plugins/ralph-wiggum>
- Ralph Orchestrator: <https://github.com/mikeyobrien/ralph-orchestrator>
