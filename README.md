# Claude Global Configuration

My global Claude Code configuration, installed via symlinks to `~/.claude/`.

## Structure

```
├── CLAUDE.md          # Global instructions and preferences
├── docs/              # Documentation and reference files
├── skills/            # Custom Claude Code skills
└── link-claude-md.sh  # Install script
```

## Installation

```bash
./link-claude-md.sh
```

This symlinks everything into `~/.claude/`:

```
~/.claude/CLAUDE.md  ->  ./CLAUDE.md
~/.claude/skills     ->  ./skills
~/.claude/docs       ->  ./docs
```

## Options

```bash
./link-claude-md.sh -n    # Dry-run (preview changes)
./link-claude-md.sh -f    # Force (backup and overwrite existing)
./link-claude-md.sh -h    # Help
```

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_HOME` | `~/.claude` | Override Claude configuration directory |

## Customization

- **CLAUDE.md** — Personal instructions, coding preferences, and conventions
- **skills/** — Custom slash commands
- **docs/** — Reference documentation accessible to Claude
