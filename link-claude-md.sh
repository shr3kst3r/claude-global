#!/usr/bin/env bash
#
# link-claude-md.sh - Install global Claude configuration via symlinks
#
# Symlinks CLAUDE.md, skills/, and docs/ into ~/.claude/
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

Install global Claude configuration by symlinking this repo's files into ~/.claude/:

    CLAUDE.md  ->  ~/.claude/CLAUDE.md
    skills/    ->  ~/.claude/skills
    docs/      ->  ~/.claude/docs

Options:
    -h, --help      Show this help message
    -f, --force     Overwrite existing files (backs up first)
    -n, --dry-run   Show what would be done without making changes

Examples:
    $(basename "$0")           # Install configuration
    $(basename "$0") -n        # Preview what would be installed
    $(basename "$0") -f        # Force reinstall (backup existing)

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

    local failed=0

    # Link CLAUDE.md
    if [[ -f "$GLOBAL_CLAUDE_MD" ]]; then
        if ! create_symlink "$GLOBAL_CLAUDE_MD" "${CLAUDE_HOME}/CLAUDE.md" "$force" "$dry_run"; then
            ((failed++)) || true
        fi
    else
        log_warn "CLAUDE.md not found: $GLOBAL_CLAUDE_MD"
    fi

    # Link skills directory
    if [[ -d "$GLOBAL_SKILLS_DIR" ]]; then
        if ! create_symlink "$GLOBAL_SKILLS_DIR" "${CLAUDE_HOME}/skills" "$force" "$dry_run"; then
            ((failed++)) || true
        fi
    else
        log_warn "Skills directory not found: $GLOBAL_SKILLS_DIR"
    fi

    # Link docs directory
    if [[ -d "$GLOBAL_DOCS_DIR" ]]; then
        if ! create_symlink "$GLOBAL_DOCS_DIR" "${CLAUDE_HOME}/docs" "$force" "$dry_run"; then
            ((failed++)) || true
        fi
    else
        log_warn "Docs directory not found: $GLOBAL_DOCS_DIR"
    fi

    if [[ $failed -gt 0 ]]; then
        die "Failed to create $failed symlink(s). Use --force to overwrite."
    fi

    if [[ "$dry_run" == false ]]; then
        echo ""
        log_success "Installation complete"
    fi
}

main "$@"
