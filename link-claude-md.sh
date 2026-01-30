#!/usr/bin/env bash
#
# link-claude-md.sh - Manage global Claude configuration symlinks
#
# Commands:
#   link [target-dir]   Symlink CLAUDE.md into a project directory
#   install             Install skills/ and docs/ into ~/.claude/
#
# Run with --help for full usage information.
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly GLOBAL_CLAUDE_MD="${SCRIPT_DIR}/CLAUDE.md"
readonly GLOBAL_SKILLS_DIR="${SCRIPT_DIR}/skills"
readonly GLOBAL_DOCS_DIR="${SCRIPT_DIR}/docs"
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
        log_success "$source_name: linked $target -> $source"
    fi

    return 0
}

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Manage global Claude configuration symlinks.

Commands:
    link [target-dir]   Symlink CLAUDE.md into a project directory
                        (default: current directory)

    install             Install skills/ and docs/ into ~/.claude/
                        Creates ~/.claude/ if it doesn't exist

Options:
    -h, --help          Show this help message
    -f, --force         Overwrite existing files (backs up first)
    -n, --dry-run       Show what would be done without making changes

Examples:
    $(basename "$0") link                     # Link CLAUDE.md in current directory
    $(basename "$0") link ~/projects/myapp    # Link CLAUDE.md in specific project
    $(basename "$0") install                  # Install skills and docs to ~/.claude/
    $(basename "$0") install -f               # Force reinstall (backup existing)
    $(basename "$0") install -n               # Preview install

Environment:
    CLAUDE_HOME         Override default ~/.claude location
EOF
}

cmd_link() {
    local force=false
    local dry_run=false
    local target_dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)  force=true; shift ;;
            -n|--dry-run) dry_run=true; shift ;;
            -*)          die "Unknown option: $1" ;;
            *)
                if [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    die "Too many arguments"
                fi
                shift
                ;;
        esac
    done

    target_dir="${target_dir:-$(pwd)}"

    # Resolve to absolute path
    if ! target_dir="$(CDPATH= cd -- "$target_dir" 2>/dev/null && pwd -P)"; then
        die "Target directory does not exist: $target_dir"
    fi

    local target_file="${target_dir}/CLAUDE.md"

    [[ -f "$GLOBAL_CLAUDE_MD" ]] || die "Global CLAUDE.md not found at: $GLOBAL_CLAUDE_MD"

    if [[ "$target_dir" == "$SCRIPT_DIR" ]]; then
        die "Cannot link CLAUDE.md to itself"
    fi

    log_info "Linking CLAUDE.md to project: $target_dir"

    if create_symlink "$GLOBAL_CLAUDE_MD" "$target_file" "$force" "$dry_run"; then
        if [[ "$dry_run" == false ]]; then
            log_success "Done"
        fi
    else
        exit 1
    fi
}

cmd_install() {
    local force=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)   force=true; shift ;;
            -n|--dry-run) dry_run=true; shift ;;
            -*)           die "Unknown option: $1" ;;
            *)            die "Unexpected argument: $1" ;;
        esac
    done

    log_info "Installing global Claude configuration to: $CLAUDE_HOME"

    # Ensure ~/.claude exists
    if [[ ! -d "$CLAUDE_HOME" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] Would create directory: $CLAUDE_HOME"
        else
            mkdir -p "$CLAUDE_HOME"
            log_info "Created directory: $CLAUDE_HOME"
        fi
    fi

    local failed=0

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
        log_info "Skills: ${CLAUDE_HOME}/skills -> ${GLOBAL_SKILLS_DIR}"
        log_info "Docs:   ${CLAUDE_HOME}/docs -> ${GLOBAL_DOCS_DIR}"
    fi
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        link)
            shift
            cmd_link "$@"
            ;;
        install)
            shift
            cmd_install "$@"
            ;;
        -*)
            die "Unknown option: $1. Use --help for usage."
            ;;
        *)
            die "Unknown command: $1. Use --help for usage."
            ;;
    esac
}

main "$@"
