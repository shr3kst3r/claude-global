#!/usr/bin/env bash
#
# install-claude-md.sh - Install global Claude configuration by copying
#
# Copies CLAUDE.md, skills/, and docs/ into ~/.claude/
#
# Run with --help for full usage information.
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

readonly GLOBAL_CLAUDE_MD="${SCRIPT_DIR}/CLAUDE.md"
readonly GLOBAL_SKILLS_DIR="${SCRIPT_DIR}/skills"
readonly GLOBAL_DOCS_DIR="${SCRIPT_DIR}/docs"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Install global Claude configuration by copying this repo's files into ~/.claude/:

    CLAUDE.md  ->  ~/.claude/CLAUDE.md
    skills/    ->  ~/.claude/skills
    docs/      ->  ~/.claude/docs

If a target already exists, you will be prompted before replacing it.

Options:
    -h, --help      Show this help message
    -f, --force     Replace existing files without prompting
    -n, --dry-run   Show what would be done without making changes

Examples:
    $(basename "$0")           # Install configuration
    $(basename "$0") -n        # Preview what would be installed
    $(basename "$0") -f        # Force reinstall without prompting

Environment:
    CLAUDE_HOME    Override default ~/.claude location (default: ~/.claude)
EOF
}

main() {
    local force=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                die "Unexpected argument: $1"
                ;;
        esac
    done

    log_info "Installing global Claude configuration to: $CLAUDE_HOME"
    log_info "Source: $SCRIPT_DIR"
    echo ""

    ensure_dir "$CLAUDE_HOME" "$dry_run"

    # Copy CLAUDE.md
    if [[ -f "$GLOBAL_CLAUDE_MD" ]]; then
        install_copy "$GLOBAL_CLAUDE_MD" "${CLAUDE_HOME}/CLAUDE.md" "$force" "$dry_run"
    else
        log_warn "CLAUDE.md not found: $GLOBAL_CLAUDE_MD"
    fi

    # Copy each skill individually (preserves user-added skills)
    if [[ -d "$GLOBAL_SKILLS_DIR" ]]; then
        ensure_dir "${CLAUDE_HOME}/skills" "$dry_run"
        for skill_dir in "$GLOBAL_SKILLS_DIR"/*/; do
            [[ -d "$skill_dir" ]] || continue
            local skill_name
            skill_name="$(basename "$skill_dir")"
            install_copy "$skill_dir" "${CLAUDE_HOME}/skills/${skill_name}" "$force" "$dry_run"
        done
    else
        log_warn "Skills directory not found: $GLOBAL_SKILLS_DIR"
    fi

    # Copy docs directory
    if [[ -d "$GLOBAL_DOCS_DIR" ]]; then
        install_copy "$GLOBAL_DOCS_DIR" "${CLAUDE_HOME}/docs" "$force" "$dry_run"
    else
        log_warn "Docs directory not found: $GLOBAL_DOCS_DIR"
    fi

    if [[ "$dry_run" == false ]]; then
        echo ""
        log_success "Installation complete"
    fi
}

main "$@"
