#!/usr/bin/env bash
#
# Feature creation utilities for Analysis Tool Kit V2
# Provides reusable functions for creating features, analyses, or any numbered directories
#

# --- Feature Creation Core Functions ---

# Gets the next available number in a directory with numbered subdirectories
# Usage: get_next_number "/path/to/parent/dir"
get_next_number() {
    local parent_dir="$1"
    mkdir -p "$parent_dir"
    
    local highest=0
    if [ -d "$parent_dir" ]; then
        for dir in "$parent_dir"/*; do
            [ -d "$dir" ] || continue
            local dirname=$(basename "$dir")
            local number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
            number=$((10#$number))
            if [ "$number" -gt "$highest" ]; then highest=$number; fi
        done
    fi
    
    local next=$((highest + 1))
    echo "$next"
}

# Gets the next available number for files in a directory (e.g., features/, apis/)
# Usage: get_next_file_number "/path/to/features"
get_next_file_number() {
    local parent_dir="$1"
    mkdir -p "$parent_dir"
    
    local highest=0
    if [ -d "$parent_dir" ]; then
        for file in "$parent_dir"/*; do
            [ -f "$file" ] || continue
            local filename=$(basename "$file")
            # Extract number from ###-name.md format
            local number=$(echo "$filename" | grep -o '^\[[0-9]\+\]' | tr -d '[]' || echo "0")
            if [[ -n "$number" ]]; then
                number=$((10#$number))
                if [ "$number" -gt "$highest" ]; then highest=$number; fi
            fi
        done
    fi
    
    local next=$((highest + 1))
    echo "$next"
}

# Formats a number with leading zeros
# Usage: format_number 5 3  # outputs "005"
format_number() {
    local number="$1"
    local width="${2:-3}"  # default width is 3
    printf "%0*d" "$width" "$number"
}

# Sanitizes a description to be safe for directory and branch names
# Usage: sanitize_name "My Feature Description"
sanitize_name() {
    local description="$1"
    echo "$description" | perl -pe 's/[^\p{L}\p{N}-]+/-/g; s/--+/-/g; s/^-|-$//g'
}

# Creates a branch name from description with automatic numbering
# Usage: create_branch_name "analysis" "My Feature" "/path/to/parent"
create_branch_name() {
    local prefix="$1"
    local description="$2"
    local parent_dir="$3"
    
    local next_num=$(get_next_number "$parent_dir")
    local formatted_num=$(format_number "$next_num")
    local sanitized_desc=$(sanitize_name "$description")
    
    # Limit to first 3 words for branch name
    local words=$(echo "$sanitized_desc" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//')
    
    echo "${prefix}/${formatted_num}-${words}"
}

# Creates a directory name from description with automatic numbering
# Usage: create_dir_name "My Feature" "/path/to/parent"
create_dir_name() {
    local description="$1"
    local parent_dir="$2"
    
    local next_num=$(get_next_number "$parent_dir")
    local formatted_num=$(format_number "$next_num")
    local sanitized_desc=$(sanitize_name "$description")
    
    echo "${formatted_num}-${sanitized_desc}"
}

# Creates a complete feature environment (branch + directory + template)
# Usage: create_feature_environment "prefix" "description" "parent_dir" "template_file" "target_filename"
create_feature_environment() {
    local branch_prefix="$1"
    local description="$2"
    local parent_dir="$3"
    local template_file="$4"
    local target_filename="${5:-spec.md}"  # default filename
    
    # Check for uncommitted changes if git is available
    if has_git && ! git diff-index --quiet HEAD --; then
        if command -v log_error >/dev/null 2>&1; then
            log_error "You have uncommitted changes. Please commit or stash them first." >&2
        else
            echo "ERROR: You have uncommitted changes. Please commit or stash them first." >&2
        fi
        return 1
    fi
    
    # Generate names
    local branch_name=$(create_branch_name "$branch_prefix" "$description" "$parent_dir")
    local dir_name=$(create_dir_name "$description" "$parent_dir")
    local feature_dir="$parent_dir/$dir_name"
    
    # Create git branch
    if has_git; then
        git checkout -b "$branch_name"
        if command -v log_info >/dev/null 2>&1; then
            log_info "Switched to new branch: $branch_name" >&2
        fi
    fi
    
    # Create directory
    mkdir -p "$feature_dir"
    if command -v log_success >/dev/null 2>&1; then
        log_success "Created directory: $feature_dir" >&2
    fi
    
    # Copy template if provided
    if [ -n "$template_file" ] && [ -f "$template_file" ]; then
        local target_file="$feature_dir/$target_filename"
        cp "$template_file" "$target_file"
        if command -v log_success >/dev/null 2>&1; then
            log_success "Created file from template: $target_file" >&2
        fi
    fi
    
    # Return information as JSON-compatible format
    cat <<EOF
BRANCH_NAME="$branch_name"
FEATURE_DIR="$feature_dir"
DIR_NAME="$dir_name"
EOF
}

# Create shared environment structure
# Usage: create_shared_environment "$analysis_base_dir" "$templates_dir"
create_shared_environment() {
    local analysis_base_dir="$1"
    local templates_dir="$2"
    local shared_dir="$analysis_base_dir/shared"
    
    # Create shared directory and subdirectories
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
            
            if command -v log_success >/dev/null 2>&1; then
                log_success "Created shared/overview.md"
            fi
        fi
    fi
    
    echo "$shared_dir"
}

# JSON output version of create_feature_environment
# Usage: create_feature_environment_json "prefix" "description" "parent_dir" "template_file"
create_feature_environment_json() {
    local result=$(create_feature_environment "$@")
    
    # Extract values
    local branch_name=$(echo "$result" | grep '^BRANCH_NAME=' | cut -d'"' -f2)
    local feature_dir=$(echo "$result" | grep '^FEATURE_DIR=' | cut -d'"' -f2)
    local dir_name=$(echo "$result" | grep '^DIR_NAME=' | cut -d'"' -f2)
    
    printf '{"BRANCH_NAME":"%s","FEATURE_DIR":"%s","DIR_NAME":"%s"}\n' \
           "$branch_name" "$feature_dir" "$dir_name"
}

# --- Template Management Functions ---

# Updates template placeholders with actual values
# Usage: update_template_placeholders "/path/to/file.md" "ProjectName" "description"
update_template_placeholders() {
    local file_path="$1"
    local project_name="$2"
    local description="$3"
    
    if [ -f "$file_path" ]; then
        # Create backup
        cp "$file_path" "${file_path}.bak"
        
        # Replace common placeholders
        sed -i.tmp "s/\[分析任務名稱\]/$project_name/g" "$file_path"
        sed -i.tmp "s/\[頁面名稱\]/$project_name/g" "$file_path"
        sed -i.tmp "s/\[功能描述\]/$description/g" "$file_path"
        sed -i.tmp "s/\[專案名稱\]/$project_name/g" "$file_path"
        
        # Clean up
        rm "${file_path}.tmp" "${file_path}.bak"
        
        if command -v log_success >/dev/null 2>&1; then
            log_success "Updated template placeholders in: $(basename "$file_path")"
        fi
    else
        if command -v log_error >/dev/null 2>&1; then
            log_error "Template file not found: $file_path"
        else
            echo "ERROR: Template file not found: $file_path" >&2
        fi
        return 1
    fi
}

# --- Validation Functions ---

# Validates that required tools are available
validate_requirements() {
    local missing_tools=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        if command -v log_error >/dev/null 2>&1; then
            log_error "Missing required tools: ${missing_tools[*]}"
        else
            echo "ERROR: Missing required tools: ${missing_tools[*]}" >&2
        fi
        return 1
    fi
    
    return 0
}

# Validates directory structure exists
validate_directory_structure() {
    local required_dirs=("$@")
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            if command -v log_warning >/dev/null 2>&1; then
                log_warning "Directory does not exist: $dir"
            else
                echo "WARNING: Directory does not exist: $dir" >&2
            fi
            mkdir -p "$dir"
            if command -v log_info >/dev/null 2>&1; then
                log_info "Created directory: $dir"
            fi
        fi
    done
}

