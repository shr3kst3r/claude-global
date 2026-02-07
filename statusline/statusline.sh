#!/usr/bin/env bash
#
# statusline.sh - Advanced Claude Code status line
#
# Displays: directory, git info, model, tokens, cost
# Receives JSON on stdin from Claude Code.
#
# Install: ./link-statusline.sh
# Test:    echo '{}' | ./statusline/statusline.sh
#

set -euo pipefail

# -- Colors (ANSI) ----------------------------------------------------------
readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'
readonly C_DIR='\033[38;5;75m'        # light blue
readonly C_BRANCH='\033[38;5;114m'    # green
readonly C_DIRTY='\033[38;5;214m'     # orange
readonly C_CLEAN='\033[38;5;114m'     # green
readonly C_AHEAD='\033[38;5;81m'      # cyan
readonly C_BEHIND='\033[38;5;203m'    # red
readonly C_MODEL='\033[38;5;183m'     # lavender
readonly C_TOKENS='\033[38;5;223m'    # warm yellow
readonly C_COST='\033[38;5;157m'      # light green
readonly C_COST_MED='\033[38;5;214m'  # orange
readonly C_COST_HIGH='\033[38;5;203m' # red
readonly C_CTX='\033[38;5;117m'       # sky blue
readonly C_CTX_WARN='\033[38;5;214m'  # orange
readonly C_CTX_CRIT='\033[38;5;203m'  # red
readonly C_SEP='\033[38;5;240m'       # dark gray

# -- Read JSON from stdin ----------------------------------------------------
INPUT=$(cat)

# Helper: extract a value from the JSON input
jval() {
    echo "$INPUT" | jq -r "$1 // empty" 2>/dev/null
}

jval_num() {
    echo "$INPUT" | jq -r "$1 // 0" 2>/dev/null
}

# -- Separator ---------------------------------------------------------------
SEP="${C_SEP}│${C_RESET}"

# -- Directory ---------------------------------------------------------------
raw_dir=$(jval '.cwd')
if [[ -z "$raw_dir" ]]; then
    raw_dir=$(jval '.workspace.current_dir')
fi
if [[ -n "$raw_dir" ]]; then
    display_dir="${raw_dir/#$HOME/~}"
else
    display_dir="~"
fi

# -- Git info ----------------------------------------------------------------
git_info=""
if [[ -n "$raw_dir" ]] && command -v git &>/dev/null; then
    if git -C "$raw_dir" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        branch=$(git -C "$raw_dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$raw_dir" rev-parse --short HEAD 2>/dev/null || echo "")

        if [[ -n "$branch" ]]; then
            # Working directory status flags
            flags=""
            if [[ -n $(git -C "$raw_dir" diff --name-only 2>/dev/null) ]]; then
                flags+="${C_DIRTY}!${C_RESET}"
            fi
            if [[ -n $(git -C "$raw_dir" ls-files --others --exclude-standard 2>/dev/null | head -1) ]]; then
                flags+="${C_DIRTY}?${C_RESET}"
            fi
            if [[ -n $(git -C "$raw_dir" diff --cached --name-only 2>/dev/null) ]]; then
                flags+="${C_CLEAN}+${C_RESET}"
            fi

            # Ahead/behind upstream
            upstream=""
            if git -C "$raw_dir" rev-parse --abbrev-ref '@{upstream}' &>/dev/null 2>&1; then
                ahead=$(git -C "$raw_dir" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
                behind=$(git -C "$raw_dir" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
                if [[ "$ahead" -gt 0 ]]; then
                    upstream+="${C_AHEAD}↑${ahead}${C_RESET}"
                fi
                if [[ "$behind" -gt 0 ]]; then
                    upstream+="${C_BEHIND}↓${behind}${C_RESET}"
                fi
            fi

            git_info="${C_BRANCH}${branch}${C_RESET}"
            [[ -n "$flags" ]] && git_info+=" ${flags}"
            [[ -n "$upstream" ]] && git_info+=" ${upstream}"
        fi
    fi
fi

# -- Model -------------------------------------------------------------------
model_name=$(jval '.model.display_name')
if [[ -z "$model_name" ]]; then
    model_id=$(jval '.model.id')
    case "$model_id" in
        *opus*)   model_name="Opus" ;;
        *sonnet*) model_name="Sonnet" ;;
        *haiku*)  model_name="Haiku" ;;
        *)        model_name="${model_id:-unknown}" ;;
    esac
fi

# -- Tokens ------------------------------------------------------------------
format_num() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

input_tokens=$(jval_num '.context_window.total_input_tokens')
output_tokens=$(jval_num '.context_window.total_output_tokens')
total_tokens=$(( input_tokens + output_tokens ))
tokens_display=$(format_num "$total_tokens")

# -- Context usage -----------------------------------------------------------
ctx_pct=$(jval_num '.context_window.used_percentage' | cut -d. -f1)
if [[ "$ctx_pct" -ge 80 ]]; then
    ctx_color="$C_CTX_CRIT"
elif [[ "$ctx_pct" -ge 60 ]]; then
    ctx_color="$C_CTX_WARN"
else
    ctx_color="$C_CTX"
fi

# Context bar (10 chars wide)
filled=$(( ctx_pct / 10 ))
empty=$(( 10 - filled ))
ctx_bar="${ctx_color}"
for ((i=0; i<filled; i++)); do ctx_bar+="█"; done
for ((i=0; i<empty; i++)); do ctx_bar+="░"; done
ctx_bar+="${C_RESET}"

# -- Cost --------------------------------------------------------------------
cost_usd=$(jval_num '.cost.total_cost_usd')
# Format cost to 4 decimal places
cost_display=$(printf '$%.4f' "$cost_usd" 2>/dev/null || echo '$0.0000')

# Color-code by cost threshold
cost_cents=$(echo "$cost_usd" | awk '{printf "%d", $1 * 100}')
if [[ "$cost_cents" -ge 100 ]]; then
    cost_color="$C_COST_HIGH"
elif [[ "$cost_cents" -ge 25 ]]; then
    cost_color="$C_COST_MED"
else
    cost_color="$C_COST"
fi

# -- Duration ----------------------------------------------------------------
duration_ms=$(jval_num '.cost.total_duration_ms')
duration_sec=$(( duration_ms / 1000 ))
if [[ "$duration_sec" -ge 3600 ]]; then
    dur_h=$(( duration_sec / 3600 ))
    dur_m=$(( (duration_sec % 3600) / 60 ))
    duration_display="${dur_h}h${dur_m}m"
elif [[ "$duration_sec" -ge 60 ]]; then
    dur_m=$(( duration_sec / 60 ))
    dur_s=$(( duration_sec % 60 ))
    duration_display="${dur_m}m${dur_s}s"
else
    duration_display="${duration_sec}s"
fi

# -- Lines changed -----------------------------------------------------------
lines_added=$(jval_num '.cost.total_lines_added')
lines_removed=$(jval_num '.cost.total_lines_removed')
lines_info=""
if [[ "$lines_added" -gt 0 || "$lines_removed" -gt 0 ]]; then
    lines_info="${C_CLEAN}+${lines_added}${C_RESET} ${C_BEHIND}-${lines_removed}${C_RESET}"
fi

# -- Assemble line 1: directory + git ----------------------------------------
line1="${C_DIR}${C_BOLD}${display_dir}${C_RESET}"
if [[ -n "$git_info" ]]; then
    line1+=" ${SEP} ${git_info}"
fi

# -- Assemble line 2: model + tokens + context + cost + duration -------------
line2="${C_MODEL}${model_name}${C_RESET}"
line2+=" ${SEP} ${C_TOKENS}${tokens_display} tok${C_RESET}"
line2+=" ${SEP} ${ctx_bar} ${ctx_color}${ctx_pct}%${C_RESET}"
line2+=" ${SEP} ${cost_color}${cost_display}${C_RESET}"
line2+=" ${SEP} ${C_DIM}${duration_display}${C_RESET}"
if [[ -n "$lines_info" ]]; then
    line2+=" ${SEP} ${lines_info}"
fi

# -- Output ------------------------------------------------------------------
printf '%b\n' "$line1"
printf '%b\n' "$line2"
