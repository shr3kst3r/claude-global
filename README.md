# Claude Global Configuration

This repository contains my global Claude Code configuration files, managed via symlinks.

## Structure

```
├── CLAUDE.md          # Global instructions and preferences
├── docs/              # Documentation and reference files
├── skills/            # Custom Claude Code skills
└── link-claude-md.sh  # Setup script
```

## Quick Start

```bash
# Install skills and docs to ~/.claude/
./link-claude-md.sh install

# Link CLAUDE.md to a project
./link-claude-md.sh link ~/projects/myapp
```

## Commands

### `install` — Set up global configuration

Symlinks `skills/` and `docs/` into `~/.claude/`:

```bash
./link-claude-md.sh install          # Install to ~/.claude/
./link-claude-md.sh install -n       # Dry-run (preview)
./link-claude-md.sh install -f       # Force (backup existing)
```

### `link` — Link CLAUDE.md to a project

Creates a symlink from a project's `CLAUDE.md` to this repo's global version:

```bash
./link-claude-md.sh link                    # Link in current directory
./link-claude-md.sh link ~/projects/myapp   # Link in specific project
./link-claude-md.sh link -f .               # Force overwrite
```

## Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help message |
| `-f, --force` | Overwrite existing files (backs up first) |
| `-n, --dry-run` | Preview changes without applying |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_HOME` | `~/.claude` | Override Claude configuration directory |

## Customization

- **CLAUDE.md** — Add your personal instructions, coding preferences, and conventions
- **skills/** — Add custom slash commands and skills
- **docs/** — Store reference documentation accessible to Claude
