#!/usr/bin/env bash
#
# link-skills.sh - Install skills individually via symlinks
#
# Finds all skill directories (containing SKILL.md) under skills/ and
# symlinks each one into ~/.claude/skills/<skill-name>.
#
# This allows skills from multiple repos to coexist in ~/.claude/skills/.
#
# Run with --help for full usage information.
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

readonly GLOBAL_SKILLS_DIR="${SCRIPT_DIR}/skills"
readonly SKILLS_TARGET="${CLAUDE_HOME}/skills"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Install skills by symlinking each skill directory into ~/.claude/skills/:

    skills/<name>/SKILL.md  ->  ~/.claude/skills/<name>

Finds all directories containing a SKILL.md under this repo's skills/ folder
and creates individual symlinks, allowing skills from multiple repos to coexist.

Options:
    -h, --help      Show this help message
    -f, --force     Overwrite existing symlinks (backs up non-symlink files first)
    -n, --dry-run   Show what would be done without making changes

Examples:
    $(basename "$0")           # Install all skills
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

    if [[ ! -d "$GLOBAL_SKILLS_DIR" ]]; then
        die "Skills directory not found: $GLOBAL_SKILLS_DIR"
    fi

    log_info "Linking skills into: $SKILLS_TARGET"
    log_info "Source: $GLOBAL_SKILLS_DIR"
    echo ""

    # If skills target is a symlink (e.g. from link-claude-md.sh), warn
    if [[ -L "$SKILLS_TARGET" ]]; then
        log_warn "$SKILLS_TARGET is a symlink to $(readlink "$SKILLS_TARGET")"
        log_warn "Individual skill linking requires a real directory, not a symlink."
        log_warn "Remove the symlink first or use --force to replace it."
        if [[ "$force" == true ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Would remove symlink and create directory: $SKILLS_TARGET"
            else
                rm "$SKILLS_TARGET"
                mkdir -p "$SKILLS_TARGET"
                log_info "Replaced symlink with directory: $SKILLS_TARGET"
            fi
        else
            die "Cannot link individual skills into a symlinked directory."
        fi
    else
        ensure_dir "$SKILLS_TARGET" "$dry_run"
    fi

    local failed=0
    local count=0

    # Find all directories containing SKILL.md
    while IFS= read -r skill_md; do
        local skill_dir
        skill_dir="$(dirname "$skill_md")"
        local skill_name
        skill_name="$(basename "$skill_dir")"

        if ! create_symlink "$skill_dir" "${SKILLS_TARGET}/${skill_name}" "$force" "$dry_run"; then
            ((failed++)) || true
        fi
        ((count++)) || true
    done < <(find "$GLOBAL_SKILLS_DIR" -name SKILL.md -type f | sort)

    if [[ $count -eq 0 ]]; then
        log_warn "No skills found in $GLOBAL_SKILLS_DIR"
        return 0
    fi

    echo ""

    if [[ $failed -gt 0 ]]; then
        die "Failed to link $failed of $count skill(s). Use --force to overwrite."
    fi

    if [[ "$dry_run" == false ]]; then
        log_success "Linked $count skill(s)"
    else
        log_info "[DRY-RUN] Would link $count skill(s)"
    fi
}

main "$@"
