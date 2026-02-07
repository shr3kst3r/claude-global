#!/usr/bin/env bash
#
# link-statusline.sh - Install the Claude Code status line
#
# Symlinks statusline.sh into ~/.claude/ and configures settings.json.
#
# Run with --help for full usage information.
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

readonly STATUSLINE_SRC="${SCRIPT_DIR}/statusline/statusline.sh"
readonly STATUSLINE_TARGET="${CLAUDE_HOME}/statusline.sh"
readonly SETTINGS_FILE="${CLAUDE_HOME}/settings.json"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Install the Claude Code status line by:
  1. Symlinking statusline.sh into ~/.claude/
  2. Adding statusLine config to ~/.claude/settings.json

Options:
    -h, --help      Show this help message
    -f, --force     Overwrite existing statusline symlink
    -n, --dry-run   Show what would be done without making changes

Examples:
    $(basename "$0")           # Install status line
    $(basename "$0") -n        # Preview installation
    $(basename "$0") -f        # Force reinstall

Environment:
    CLAUDE_HOME    Override default ~/.claude location (default: ~/.claude)
EOF
}

# Update settings.json with statusLine configuration
update_settings() {
    local dry_run="$1"
    local statusline_cmd="~/.claude/statusline.sh"

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] Would create $SETTINGS_FILE with statusLine config"
            return 0
        fi
        # Create new settings file
        cat > "$SETTINGS_FILE" <<EOJSON
{
  "statusLine": {
    "type": "command",
    "command": "${statusline_cmd}"
  }
}
EOJSON
        log_success "Created $SETTINGS_FILE with statusLine config"
        return 0
    fi

    # Check if statusLine is already configured
    if jq -e '.statusLine' "$SETTINGS_FILE" &>/dev/null; then
        local current_cmd
        current_cmd=$(jq -r '.statusLine.command // empty' "$SETTINGS_FILE")
        if [[ "$current_cmd" == "$statusline_cmd" ]]; then
            log_success "settings.json: statusLine already configured"
            return 0
        fi
        log_warn "settings.json: statusLine exists with different command: $current_cmd"
    fi

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] Would add statusLine config to $SETTINGS_FILE"
        return 0
    fi

    # Merge statusLine config into existing settings
    local tmp
    tmp=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "'"${statusline_cmd}"'"}}' \
        "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"

    log_success "settings.json: statusLine config added"
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

    if [[ ! -f "$STATUSLINE_SRC" ]]; then
        die "Status line script not found: $STATUSLINE_SRC"
    fi

    log_info "Installing Claude Code status line"
    log_info "Source: $STATUSLINE_SRC"
    echo ""

    ensure_dir "$CLAUDE_HOME" "$dry_run"

    # 1. Symlink the script
    if ! create_symlink "$STATUSLINE_SRC" "$STATUSLINE_TARGET" "$force" "$dry_run"; then
        die "Failed to create symlink. Use --force to overwrite."
    fi

    # 2. Configure settings.json
    update_settings "$dry_run"

    if [[ "$dry_run" == false ]]; then
        echo ""
        log_success "Status line installed! Restart Claude Code to activate."
    fi
}

main "$@"
