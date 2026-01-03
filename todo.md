# TODO: Refactor verify.md to use Skills

## Issues

- [ ] **Item 1**: `verify.md` mentions "npm" directly (e.g., `npm test`, `npm run lint`) instead of getting the agent to identify the package manager first. Should use `ni`/`nr`/`nx` or reference a skill that handles package manager detection.

- [ ] **Item 2**: `verify.md` hardcodes language-specific commands for unit testing (Node.js: `npm test`, Python: `pytest`) directly in the agent file, instead of referencing information from a `SKILL.md` that encapsulates this knowledge.

- [ ] **Item 3**: Detect scripts logic should reference skills. Each language ecosystem should have its own skill for discovering available scripts:
  - `skills/detect-scripts/nodejs/` - How to find scripts in package.json
  - `skills/detect-scripts/python/` - How to find scripts in pyproject.toml, setup.py, etc.
  - `skills/detect-scripts/rust/` - How to find scripts/commands in Cargo.toml
  - `skills/detect-scripts/csharp/` - How to find scripts in .csproj files
  - `skills/detect-scripts/go/` - How to find commands in go.mod projects
  - etc.

- [ ] **Item 4**: Agent files (plan.md, code.md, test.md, qa.md) should all use `opus` model instead of `sonnet`. These are complex coding tasks that benefit from Opus's stronger reasoning capabilities.

- [ ] **Item 5**: Create a conventional commits skill that encapsulates commit message formatting. Should include:
  - Conventional commit format with Linear issue ID
  - Commit message structure (feat/fix/refactor/test/chore)
  - Issue priority definitions (P0-P3)
  - Issue format guidelines (title, description, acceptance criteria, test steps)
  - Location: `skills/conventional-commits/SKILL.md`

- [ ] **Item 6**: Create a universal package manager abstraction. Currently agents reference `npm`, `npx` directly, but projects could be Python, Node, Rust, Go, etc. Need a single unified interface (like `ni` but cross-language):
  - Detect project type automatically (package.json, pyproject.toml, Cargo.toml, go.mod, etc.)
  - Unified commands that translate to the correct package manager:
    - `install` → npm install / pip install / cargo build / go mod download
    - `add <pkg>` → npm install <pkg> / pip install <pkg> / cargo add <pkg>
    - `run <script>` → npm run / python -m / cargo run
    - `exec <bin>` → npx / pipx / cargo run --bin
    - `test` → npm test / pytest / cargo test / go test
  - Build our own CLI tool (similar to ni but language-agnostic)
  - Replaces all hardcoded package manager references in agents

- [ ] **Item 7**: Create a universal testing framework abstraction. Currently agents reference `vitest`, `jest`, `pytest` directly, but projects could be Python, Node, Rust, Go, etc. Need a single unified interface (like `ni` but cross-language):

- [ ] **Item 8**: Review agent to ensure it actually uses claude code chrome extension not playwright and manually checks the app via the browser. Check the ~/.claude/projects/

- [ ] **Item 9**: Switch playwright MCP to <https://github.com/vibheksoni/stealth-browser-mcp>
