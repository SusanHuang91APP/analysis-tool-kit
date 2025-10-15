#!/usr/bin/env bash
#
# Common functions and variables for the Analysis Tool Kit.
# Inspired by the robust structure of spec-kit's common.sh.
#

# --- Loggers ---
log_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
log_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
log_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# --- Load Feature Utilities ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/feature-utils.sh" ]; then
    source "$SCRIPT_DIR/feature-utils.sh"
fi

# --- Git & Path Helpers ---
get_repo_root() { git rev-parse --show-toplevel 2>/dev/null || pwd; }
get_current_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git"; }
has_git() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# Get file extension for syntax highlighting
get_file_extension() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    local extension="${filename##*.}"
    
    # Map common extensions to syntax highlighter names
    case "$extension" in
        "ts") echo "typescript" ;;
        "js") echo "javascript" ;;
        "cshtml"|"html") echo "html" ;;
        "cs") echo "csharp" ;;
        "css") echo "css" ;;
        "scss") echo "scss" ;;
        "json") echo "json" ;;
        "md") echo "markdown" ;;
        "sh") echo "bash" ;;
        "py") echo "python" ;;
        *) echo "$extension" ;;
    esac
}

# Checks if the current branch is a valid analysis branch.
check_analysis_branch() {
    local branch="$1"
    if [[ ! "$branch" =~ ^analysis/[0-9]{3}- ]]; then
        log_error "Not on a valid analysis branch. Current branch: $branch"
        log_error "Analysis branches should be named like: analysis/001-feature-name"
        return 1
    fi
    return 0
}

# Get the actual location of .analysis-tool-kit directory
get_kit_location() {
    # Start from current script directory and search upward
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local kit_dir="$(dirname "$current_dir")"  # Go up from scripts/ to .analysis-tool-kit/
    echo "$kit_dir"
}

# Centralized path management, inspired by spec-kit's get_feature_paths.
# Usage: eval $(get_analysis_paths)
get_analysis_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local kit_dir="$(get_kit_location)"
    local kit_parent_dir="$(dirname "$kit_dir")"  # Parent directory of .analysis-tool-kit
    local page_analysis_dir=""
    if [[ "$current_branch" =~ ^analysis/ ]]; then
        # Extract the part after "analysis/" from the branch name
        local analysis_suffix="${current_branch#analysis/}"
        page_analysis_dir="$kit_parent_dir/analysis/$analysis_suffix"
    fi

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
KIT_DIR='$kit_dir'
KIT_PARENT_DIR='$kit_parent_dir'
PAGE_ANALYSIS_DIR='$page_analysis_dir'
OVERVIEW_FILE='$page_analysis_dir/overview.md'
README_FILE='$page_analysis_dir/README.md'
CONSTITUTION_FILE='$kit_dir/memory/constitution.md'
EOF
}

# --- Analysis Environment Helpers ---
# These functions are now deprecated - use feature-utils.sh functions instead

# Legacy wrapper for backward compatibility
get_next_analysis_num() {
    local kit_dir="$(get_kit_location)"
    local kit_parent_dir="$(dirname "$kit_dir")"
    local analysis_base_dir="$kit_parent_dir/analysis"
    get_next_number "$analysis_base_dir"
}

# Legacy wrapper for backward compatibility  
sanitize_description() {
    sanitize_name "$1"
}