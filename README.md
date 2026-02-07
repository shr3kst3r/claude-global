# Claude Global Configuration

My global Claude Code configuration, installed via symlinks to `~/.claude/`.

## Structure

```
├── CLAUDE.md          # Global instructions and preferences
├── docs/              # Documentation and reference files
├── skills/            # Custom Claude Code skills
│   ├── knowledge-base-article/
│   └── topic-intro/
├── lib/
│   └── common.sh      # Shared shell utilities
├── link-claude-md.sh  # Install script (links everything)
└── link-skills.sh     # Install script (links individual skills)
```

## Installation

### Link everything

Symlinks `CLAUDE.md`, `skills/`, and `docs/` into `~/.claude/`:

```bash
./link-claude-md.sh
```

### Link individual skills

Symlinks each skill directory into `~/.claude/skills/<name>`, allowing skills from multiple repos to coexist:

```bash
./link-skills.sh
```

## Options

Both scripts support the same flags:

```bash
-n, --dry-run   # Preview changes without making them
-f, --force     # Backup and overwrite existing files
-h, --help      # Show help
```

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_HOME` | `~/.claude` | Override Claude configuration directory |

## Skills

| Skill | Description |
|-------|-------------|
| `knowledge-base-article` | Generate structured knowledge base articles |
| `topic-intro` | Generate comprehensive introduction docs for learning a topic |

## Customization

- **CLAUDE.md** — Personal instructions, coding preferences, and conventions
- **skills/** — Custom skills extending Claude's capabilities
- **docs/** — Reference documentation accessible to Claude
