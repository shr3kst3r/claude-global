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

# Copy a file or directory to target, prompting if target already exists
# Args: source target force dry_run
install_copy() {
    local source="$1"
    local target="$2"
    local force="$3"
    local dry_run="$4"
    local source_name
    source_name="$(basename "$source")"

    if [[ -L "$target" || -e "$target" ]]; then
        # Check if contents are identical
        local has_diff=false
        if [[ -d "$source" ]]; then
            diff -rq "$target" "$source" &>/dev/null || has_diff=true
        else
            diff -q "$target" "$source" &>/dev/null || has_diff=true
        fi

        if [[ "$has_diff" == false ]]; then
            log_success "$source_name: up to date"
            return 0
        fi

        if [[ -L "$target" ]]; then
            log_warn "$source_name: symlink exists at $target -> $(readlink "$target")"
        else
            log_warn "$source_name: already exists at $target"
        fi

        # Show colored diff
        if [[ -d "$source" ]]; then
            diff -r --color=always "$target" "$source" 2>/dev/null || true
        else
            diff --color=always "$target" "$source" 2>/dev/null || true
        fi
        echo ""

        if [[ "$force" == true ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Would replace: $target"
            else
                rm -rf "$target"
            fi
        elif [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] Would ask to replace: $target"
        else
            printf "${YELLOW}Replace %s? [y/N]${NC} " "$target"
            local reply
            read -r reply
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                rm -rf "$target"
            else
                log_info "$source_name: skipped"
                return 0
            fi
        fi
    fi

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] Would copy: $source -> $target"
    else
        if [[ -d "$source" ]]; then
            cp -R "$source" "$target"
        else
            cp "$source" "$target"
        fi
        log_success "$source_name: installed"
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
