#!/usr/bin/env bash
#
# Common functions and variables for the Analysis Tool Kit V2.
# Provides core utilities for path management, quality tracking, and overview updates.
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
        "tsx") echo "tsx" ;;
        "js") echo "javascript" ;;
        "jsx") echo "jsx" ;;
        "cshtml"|"html") echo "html" ;;
        "cs") echo "csharp" ;;
        "css") echo "css" ;;
        "scss") echo "scss" ;;
        "json") echo "json" ;;
        "md") echo "markdown" ;;
        "sh") echo "bash" ;;
        "py") echo "python" ;;
        "vue") echo "vue" ;;
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

# Get the actual location of .analysis-kit directory
get_kit_location() {
    # Start from current script directory and search upward
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local kit_dir="$(dirname "$current_dir")"  # Go up from scripts/ to .analysis-kit/
    echo "$kit_dir"
}

# Centralized path management for V2 architecture
# Usage: eval $(get_analysis_paths)
get_analysis_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local kit_dir="$(get_kit_location)"
    local kit_parent_dir="$(dirname "$kit_dir")"  # Parent directory of .analysis-kit
    local analysis_base_dir="$kit_parent_dir/analysis"
    local shared_dir="$analysis_base_dir/shared"
    local topic_dir=""
    
    if [[ "$current_branch" =~ ^analysis/ ]]; then
        # Extract the part after "analysis/" from the branch name
        local analysis_suffix="${current_branch#analysis/}"
        topic_dir="$analysis_base_dir/$analysis_suffix"
    fi

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
KIT_DIR='$kit_dir'
KIT_PARENT_DIR='$kit_parent_dir'
ANALYSIS_BASE_DIR='$analysis_base_dir'
SHARED_DIR='$shared_dir'
TOPIC_DIR='$topic_dir'
CONSTITUTION_FILE='$kit_dir/memory/constitution.md'
TEMPLATES_DIR='$kit_dir/templates'
EOF
}

# Get overview.md path based on file category
# Usage: get_overview_path "topic" "$TOPIC_DIR" or get_overview_path "shared" "$SHARED_DIR"
get_overview_path() {
    local category="$1"  # "topic" or "shared"
    local target_dir="$2"
    
    if [[ "$category" == "shared" ]]; then
        echo "$target_dir/overview.md"
    else
        echo "$target_dir/overview.md"
    fi
}

# Ensure shared directory structure exists
ensure_shared_structure() {
    local shared_dir="$1"
    local templates_dir="$2"
    
    # Create shared directory if not exists
    mkdir -p "$shared_dir"
    
    # Create subdirectories
    mkdir -p "$shared_dir/request-pipeline"
    mkdir -p "$shared_dir/components"
    mkdir -p "$shared_dir/helpers"
    
    # Create shared overview.md if not exists
    local overview_file="$shared_dir/overview.md"
    if [[ ! -f "$overview_file" ]]; then
        local overview_template="$templates_dir/overview-template.md"
        if [[ -f "$overview_template" ]]; then
            cp "$overview_template" "$overview_file"
            
            # Update template placeholders
            local current_date=$(date +%Y-%m-%d)
            sed -i.bak \
                -e "s/\[Topic Name\]/Shared Components/g" \
                -e "s/\[YYYY-MM-DD\]/$current_date/g" \
                "$overview_file"
            rm -f "${overview_file}.bak"
            
            log_success "Created shared/overview.md"
        else
            log_warning "Overview template not found: $overview_template"
        fi
    fi
}

# Determine file category (topic or shared)
# Usage: get_file_category "feature" or get_file_category "component"
get_file_category() {
    local type="$1"
    
    case "$type" in
        server|client|feature|api)
            echo "topic"
            ;;
        request-pipeline|component|helper)
            echo "shared"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Get target directory based on type
# Usage: get_target_directory "$TOPIC_DIR" "$SHARED_DIR" "feature"
get_target_directory() {
    local topic_dir="$1"
    local shared_dir="$2"
    local type="$3"
    
    local category=$(get_file_category "$type")
    
    case "$type" in
        server|client)
            echo "$topic_dir"
            ;;
        feature)
            echo "$topic_dir/features"
            ;;
        api)
            echo "$topic_dir/apis"
            ;;
        request-pipeline)
            echo "$shared_dir/request-pipeline"
            ;;
        component)
            echo "$shared_dir/components"
            ;;
        helper)
            echo "$shared_dir/helpers"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Calculate quality level based on completion percentage
# Usage: calculate_quality_level 75
calculate_quality_level() {
    local percentage="$1"
    
    if [[ $percentage -eq 0 ]]; then
        echo "📝 待分析"
    elif [[ $percentage -le 40 ]]; then
        echo "⭐ 基礎框架"
    elif [[ $percentage -le 70 ]]; then
        echo "⭐⭐⭐ 邏輯完成"
    elif [[ $percentage -le 90 ]]; then
        echo "⭐⭐⭐⭐ 架構完整"
    else
        echo "⭐⭐⭐⭐⭐ 完整分析"
    fi
}

# Update overview.md manifest with new file entry
# Usage: update_overview_manifest "$overview_file" "$file_name" "$file_path" "$quality_level"
update_overview_manifest() {
    local overview_file="$1"
    local file_name="$2"
    local relative_path="$3"
    local quality_level="${4:-📝 待分析}"
    
    if [[ ! -f "$overview_file" ]]; then
        log_error "Overview file not found: $overview_file"
        return 1
    fi
    
    # Check if entry already exists
    if grep -q "| \[$file_name\]" "$overview_file"; then
        log_info "Entry already exists in overview.md: $file_name"
        return 0
    fi
    
    # Find the table and add new entry
    # Look for the line after "| 檔案 | 品質等級 |" or "|------|----------|"
    local table_marker="|------|----------|"
    
    if grep -q "$table_marker" "$overview_file"; then
        # Add entry after table header
        sed -i.bak "/$table_marker/a\\
| [$file_name]($relative_path) | $quality_level |
" "$overview_file"
        rm -f "${overview_file}.bak"
        log_success "Added entry to overview.md: $file_name"
    else
        log_warning "Could not find table marker in overview.md"
        return 1
    fi
}

# Update quality level for existing entry in overview.md
# Usage: update_quality_level "$overview_file" "$file_name" "$new_quality_level"
update_quality_level() {
    local overview_file="$1"
    local file_name="$2"
    local new_quality_level="$3"
    
    if [[ ! -f "$overview_file" ]]; then
        log_error "Overview file not found: $overview_file"
        return 1
    fi
    
    # Find and update the quality level for the specific file
    # Pattern: | [filename](...) | <old quality> |
    sed -i.bak "s#| \[$file_name\]([^)]*) | [^|]* |#| [$file_name](\1) | $new_quality_level |#" "$overview_file"
    rm -f "${overview_file}.bak"
    
    log_success "Updated quality level for $file_name: $new_quality_level"
}

# Count checked items in quality checklist
# Usage: count_checked_items "$file_path"
count_checked_items() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        echo "0"
        return
    fi
    
    # Count checked items: - [x]
    local checked=$(grep -c "^- \[x\]" "$file_path" 2>/dev/null || echo "0")
    
    # Count total items: - [ ] or - [x]
    local total=$(grep -c "^- \[\(x\| \)\]" "$file_path" 2>/dev/null || echo "0")
    
    if [[ $total -eq 0 ]]; then
        echo "0"
    else
        # Calculate percentage
        local percentage=$((checked * 100 / total))
        echo "$percentage"
    fi
}

# Validate required tools
validate_requirements() {
    local missing_tools=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Legacy wrappers for backward compatibility
get_next_analysis_num() {
    local kit_dir="$(get_kit_location)"
    local kit_parent_dir="$(dirname "$kit_dir")"
    local analysis_base_dir="$kit_parent_dir/analysis"
    get_next_number "$analysis_base_dir"
}

sanitize_description() {
    sanitize_name "$1"
}

