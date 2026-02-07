#!/usr/bin/env bash
#
# common.sh - Shared utilities for Claude configuration scripts
#
# Source this file after defining SCRIPT_DIR:
#   readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib/common.sh"
#

readonly CLAUDE_HOME="${CLAUDE_HOME:-${HOME}/.claude}"

# Colors for output (disabled if not a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC}   %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }

die() {
    log_error "$*"
    exit 1
}

# Create a symlink, handling existing files/links
# Args: source target force dry_run
create_symlink() {
    local source="$1"
    local target="$2"
    local force="$3"
    local dry_run="$4"
    local source_name
    source_name="$(basename "$source")"

    if [[ -L "$target" ]]; then
        local current_target
        current_target="$(readlink "$target")"

        if [[ "$current_target" == "$source" ]]; then
            log_success "$source_name: symlink already correct"
            return 0
        fi

        log_warn "$source_name: symlink exists but points to: $current_target"

        if [[ "$force" == true ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Would remove existing symlink: $target"
            else
                rm "$target"
            fi
        else
            log_error "$source_name: use --force to overwrite"
            return 1
        fi

    elif [[ -e "$target" ]]; then
        log_warn "$source_name: file/directory already exists at $target"

        if [[ "$force" == true ]]; then
            local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"

            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Would backup to: $backup"
            else
                mv "$target" "$backup"
                log_info "$source_name: backed up to $backup"
            fi
        else
            log_error "$source_name: use --force to backup and replace"
            return 1
        fi
    fi

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] Would create: $target -> $source"
    else
        ln -s "$source" "$target"
        log_success "$source_name: linked"
    fi

    return 0
}

# Ensure a directory exists, creating it if needed
# Args: dir dry_run
ensure_dir() {
    local dir="$1"
    local dry_run="$2"

    if [[ ! -d "$dir" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] Would create directory: $dir"
        else
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    fi
}
