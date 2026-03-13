# Claude Global Configuration

My global Claude Code configuration, installed by copying into `~/.claude/`.

## Structure

```
├── CLAUDE.md             # Global instructions and preferences
├── docs/                 # Documentation and reference files
├── skills/               # Custom Claude Code skills
│   ├── knowledge-base-article/
│   └── topic-intro/
├── statusline/
│   └── statusline.sh     # Advanced status line script
├── lib/
│   └── common.sh         # Shared shell utilities
├── install-claude-md.sh  # Install script (copies everything)
├── install-skills.sh     # Install script (copies individual skills)
└── install-statusline.sh # Install script (copies status line)
```

## Installation

### Install everything

Copies `CLAUDE.md`, `skills/`, and `docs/` into `~/.claude/`:

```bash
./install-claude-md.sh
```

### Install individual skills

Copies each skill directory into `~/.claude/skills/<name>`, allowing skills from multiple repos to coexist:

```bash
./install-skills.sh
```

### Install status line

Copies `statusline.sh` into `~/.claude/` and adds `statusLine` config to `settings.json`:

```bash
./install-statusline.sh
```

## Options

All scripts support the same flags:

```bash
-n, --dry-run   # Preview changes without making them
-f, --force     # Replace existing files without prompting
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

## Status Line

Two-line display with color-coded information:

```
~/src/myproject │ main !? ↑2
Opus │ 58,120 tok │ ██░░░░░░░░ 28% │ $0.1534 │ 3m5s │ +42 -7
```

**Line 1** — Directory (with `~` home replacement) + git branch, dirty flags (`!` modified, `?` untracked, `+` staged), ahead/behind upstream (`↑N`/`↓M`)

**Line 2** — Model name, total tokens, context bar with percentage, session cost (green < $0.25, orange < $1.00, red >= $1.00), duration, lines changed

## Customization

- **CLAUDE.md** — Personal instructions, coding preferences, and conventions
- **skills/** — Custom skills extending Claude's capabilities
- **docs/** — Reference documentation accessible to Claude
- **statusline/** — Status line script for Claude Code
