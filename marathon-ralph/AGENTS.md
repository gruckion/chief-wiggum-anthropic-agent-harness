# Marathon Ralph

Autonomous development plugin. Creates Linear projects from specs, works through issues with verify-plan-code-test-qa loop.

## Commands

| Command | Description |
|---------|-------------|
| `/marathon-ralph:run <spec>` | Start new marathon from spec file |
| `/marathon-ralph:run` | Resume existing marathon |
| `/marathon-ralph:status` | Show progress and current issue |
| `/marathon-ralph:cancel` | Stop marathon (preserves Linear project) |

## Critical Warnings

### Next.js/React SSR

- **ALWAYS run `npm run build`** before marking issues complete - catches hydration errors missed by dev mode
- **Never nest interactive elements**: `<button>` inside `<button>`, `<a>` inside `<button>`, etc.
- **DialogTrigger + Button = invalid HTML** if DialogTrigger renders as button (use `asChild`)
- Hydration errors often only appear in production build, not dev server

### HTML Validity

- Check component composition - wrapper components may render invalid nesting
- `<button>` can only contain phrasing content (no `<div>`, no nested buttons)
- When in doubt, inspect rendered HTML structure

### E2E Tests

- **Monitor browser console** for errors during tests - tests can pass while app has runtime errors
- Use `page.on('console', ...)` or `page.on('pageerror', ...)` to catch React errors
- Failed hydration = broken app even if tests "pass"

## Development Loop

```markdown
VERIFY → PLAN → CODE → TEST → QA → DONE
```

## Prerequisites

Linear MCP required:

```bash
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

## Package Manager

Use `ni` (auto-detects package manager):

- `ni` / `ni -D <pkg>` - Install
- `nr <script>` - Run script
- `nx <bin>` - Execute binary

## State

Stored in `.claude/marathon-ralph.json`. Session-scoped via `session_id`.
