# Claude Code Marketplace Boilerplate

A minimal boilerplate template for creating and distributing Claude Code plugins via the marketplace. This project provides a structured foundation for building custom commands, agents and hooks — tools that extend Claude Code's capabilities.

## Overview

This boilerplate helps you create professional Claude Code plugins with:

- **Custom Commands**: Slash commands for common workflows
- **Specialized Agents**: AI agents optimized for specific tasks
- **Skills**: Modular knowledge packages with workflows and bundled resources
- **Event Hooks**: Automated responses to IDE events
- **MCP Integration**: Model Context Protocol server configuration
- **Marketplace Ready**: Pre-configured metadata for distribution

## Project Structure

```
.
├── .claude-plugin/
│   └── marketplace.json          # Marketplace configuration
├── plugins/
│   └── webapp-starter/           # Example plugin
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin metadata
│       ├── agents/
│       │   └── webapp-uidesigner.md
│       ├── commands/
│       │   ├── webapp-starter.md
│       │   └── generate-random-personas.md
│       ├── skills/
│       │   └── skill-creator/
│       │       └── SKILL.md      # Skill definition
│       ├── hooks/
│       │   └── hooks.json        # Event hooks configuration
│       └── .mcp.json            # MCP servers configuration
└── README.md
```

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/halans/cc-marketplace-boilerplate
cd cc-marketplace-boilerplate
```

### 2. Configure Your Marketplace

Edit [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json):

```json
{
  "name": "your-marketplace-name",
  "owner": {
    "name": "Your Name",
    "email": "your@email.com",
    "url": "https://github.com/yourusername"
  },
  "metadata": {
    "description": "Your marketplace description",
    "version": "1.0.0"
  },
  "plugins": [...]
}
```

### 3. Create Your Plugin

Use the included `webapp-starter` plugin as a template:

1. Copy the plugin directory structure
2. Update plugin metadata in `.claude-plugin/plugin.json`
3. Add your custom commands, agents, skills, and hooks
4. Register the plugin in `marketplace.json`

## Plugin Components

### Commands

Commands are slash commands that users can invoke in Claude Code. Create a markdown file in `commands/`:

```markdown
---
description: Your command description
---

Your command prompt and instructions here.
```

Usage: `/your-command`

### Agents

Agents are specialized AI assistants for specific tasks. Create a markdown file in `agents/`:

```markdown
---
name: agent-name
description: Agent description
model: sonnet
---

Your agent's system prompt and behavior instructions.
```

### Skills

Skills are modular packages that extend Claude's capabilities with specialized knowledge, workflows, and tool integrations. They transform Claude into a domain-specific expert by providing procedural knowledge and reusable resources.

Create a skill directory with a `SKILL.md` file:

```
skills/
└── skill-name/
    ├── SKILL.md (required)
    ├── scripts/ (optional)
    ├── references/ (optional)
    └── assets/ (optional)
```

**SKILL.md structure:**

```markdown
---
name: skill-name
description: When and why this skill should be used
---

# Skill Name

Instructions and workflows for Claude to follow when using this skill.

## Usage

Detailed guidance on how to apply this skill.
```

**Optional bundled resources:**

- **scripts/**: Executable code for deterministic tasks (Python, Bash, etc.)
- **references/**: Documentation loaded as needed (schemas, API docs, policies)
- **assets/**: Files used in output (templates, icons, boilerplate code)

### Hooks

Hooks automate responses to events like tool usage. Configure in `hooks/hooks.json`:

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "echo 'Hook executed!'"
        }
      ]
    }
  ]
}
```

### MCP Servers

Integrate Model Context Protocol servers via `.mcp.json`:

For example on Linux/Mac, using npx to run a package:
```json
{
  "mcpServers": {
    "[server-name]": {
      "command": "npx",
      "args": ["[package-name]", "args"]
    }
  }
}
```

On Windows, using npx to run a package:
```json
{
  "mcpServers": {
    "[server-name]": {
      "command": "cmd",
      "args": ["/c", "npx","[package-name]", "args"]
    }
  }
}
```

## Example Plugin: webapp-starter

The included example plugin demonstrates:

- **Commands**:
  - `/webapp-starter` - Create a basic SPA website structure example command
  - `/generate-random-personas` - Generate random user personas example command

- **Agents**:
  - `webapp-uidesigner` - UI design and styling specialist example agent

- **Skills**:
  - `skill-creator` - Anthropic's skill-creator skill as guide for creating effective skills with workflows and bundled resources, as example skill

- **Hooks**:
  - Post-edit confirmation messages example hook

- **MCP Integration**:
  - shadcn component library integration example MCP server configuration

## Plugin Metadata

Each plugin requires a `plugin.json` file:

```json
{
  "name": "plugin-name",
  "description": "Plugin description",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "your@email.com"
  }
}
```
Make sure that the plugin here matches the entry in `marketplace.json`.

## Best Practices

1. **Clear Descriptions**: Write concise, actionable descriptions for commands and agents
2. **Version Control**: Use semantic versioning (MAJOR.MINOR.PATCH)
3. **Documentation**: Document each command's purpose and usage
4. **Testing**: Test commands and agents thoroughly before publishing
5. **Keywords**: Add relevant keywords for marketplace discoverability

## Categories

Choose appropriate categories for your plugins:
- web application
- frontend
- backend
- fullstack
- developer tools
- productivity
- testing
- documentation

## Publishing

1. Ensure all metadata is complete and accurate
2. Test your plugin locally in Claude Code  
  -- add local marketplace through /plugin > Add Marketplace > using ./    
  -- exit and restart claude code for it to pick up the plugin and mcp 
3. Update version numbers appropriately
4. Submit to the Claude Code Marketplace

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Add your license here]

## Support

For issues or questions:
- GitHub Issues: [Add your repository URL]

## Resources

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Claude Code Marketplace Guidelines](https://docs.claude.com/claude-code/marketplace)
- [Model Context Protocol](https://modelcontextprotocol.io/)

---

Built with ❤️ for the Claude Code community
