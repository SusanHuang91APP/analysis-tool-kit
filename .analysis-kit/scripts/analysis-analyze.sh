#!/usr/bin/env bash
#
# Analyze and update existing analysis files with quality tracking
# This script validates environment and calculates quality levels
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
eval $(get_analysis_paths)

show_help() {
    echo "Usage: $0 <target_file> [source-files...]"
    echo ""
    echo "Description:"
    echo "  Analyzes source files and updates an existing analysis document."
    echo "  Automatically calculates and updates quality level in overview.md"
    echo ""
    echo "Arguments:"
    echo "  <target_file>      The .md file to update (e.g., \"features/001-login\")"
    echo "  [source-files...]  Source code files to analyze"
    echo ""
    echo "Quality Levels:"
    echo "  📝 待分析         - 0% complete"
    echo "  ⭐ 基礎框架       - 1-40% complete"
    echo "  ⭐⭐⭐ 邏輯完成   - 41-70% complete"
    echo "  ⭐⭐⭐⭐ 架構完整 - 71-90% complete (all dependencies analyzed)"
    echo "  ⭐⭐⭐⭐⭐ 完整分析 - 91-100% complete"
    echo ""
    echo "Examples:"
    echo "  # Analyze feature"
    echo "  $0 \"features/001-login\" Controllers/LoginController.cs Services/AuthService.cs"
    echo ""
    echo "  # Update API analysis"
    echo "  $0 \"apis/001-get-user\" Routes/api/users.ts"
    echo ""
    echo "  # Update server.md"
    echo "  $0 \"server.md\" Controllers/HomeController.cs"
}

# --- Process a single analysis file ---
# This function handles the analysis for one markdown file and its sources.
process_analysis_file() {
    local target_arg="$1"
    shift
    local source_files_arr=("$@")

    local target_file=""
    local overview_file="$TOPIC_DIR/overview.md"

    # --- Resolve Target File Path ---
    local search_dirs=(
        "$TOPIC_DIR"
        "$TOPIC_DIR/features"
        "$TOPIC_DIR/apis"
        "$TOPIC_DIR/helpers"
        "$TOPIC_DIR/components"
        "$TOPIC_DIR/request-pipeline"
    )

    for dir in "${search_dirs[@]}"; do
        if [[ -f "$dir/$target_arg" ]]; then
            target_file="$dir/$target_arg"
            break
        elif [[ -f "$dir/${target_arg}.md" ]]; then
            target_file="$dir/${target_arg}.md"
            break
        fi
    done

    if [[ -z "$target_file" ]]; then
        log_error "Target file not found: $target_arg" >&2
        return 1
    fi

    log_success "Processing target file: $(basename "$target_file")"

    # --- Validate Source Files ---
    if [[ ${#source_files_arr[@]} -gt 0 ]]; then
        for source_file in "${source_files_arr[@]}"; do
            if [[ ! -f "$source_file" ]]; then
                log_warning "Source file not found: $source_file"
            fi
        done
    fi

    # --- Prepare environment for AI ---
    echo ""
    echo "=== Environment Variables for AI: $(basename "$target_file") ==="
    echo "TARGET_FILE='$target_file'"
    echo "OVERVIEW_FILE='$overview_file'"
    echo "CONSTITUTION_FILE='$CONSTITUTION_FILE'"
    log_info "Source files: ${source_files_arr[*]}"
    echo ""
}

# --- Main Logic ---

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1

if [[ ! -d "$TOPIC_DIR" ]]; then
    log_error "Topic directory not found: $TOPIC_DIR" >&2
    log_error "Run /analysis.init first." >&2
    exit 1
fi

# --- Mode Selection: Batch or Single ---
if [ "$#" -eq 0 ]; then
    # --- Batch Mode ---
    log_info "Mode: Batch. Processing all files from $TOPIC_DIR/overview.md."
    OVERVIEW_FILE="$TOPIC_DIR/overview.md"
    if [[ ! -f "$OVERVIEW_FILE" ]]; then
        log_error "Overview file not found: $OVERVIEW_FILE" >&2
        exit 1
    fi

    # Extract relative paths from overview.md, e.g., (./features/001-login.md)
    RELATIVE_PATHS=()
    while IFS= read -r path; do
        RELATIVE_PATHS+=("$path")
    done < <(grep -o '(\./[^)]*\.md)' "$OVERVIEW_FILE" | sed 's/[()]/''/g; s|^\./||')

    for rel_path in "${RELATIVE_PATHS[@]}"; do
        md_file="$TOPIC_DIR/$rel_path"
        if [[ ! -f "$md_file" ]]; then
            log_warning "File from overview.md not found: $md_file. Skipping."
            continue
        fi

        log_info "--------------------------------------------------"
        log_info "Batch processing: $(basename "$md_file")"

        # Extract source code files from the markdown itself
        SOURCE_CODE_FILES_FROM_MD=()
        in_section=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^"### 1.1 📂 分析檔案資訊" ]]; then
                in_section=true
                continue
            fi
            if $in_section && [[ "$line" =~ ^"###" ]]; then
                break
            fi
            if $in_section; then
                if [[ "$line" =~ \|([^|]+)\| ]]; then
                    path_candidate=$(echo "${BASH_REMATCH[1]}" | xargs)
                    if [[ "$path_candidate" =~ \. ]]; then
                        if [[ -f "$REPO_ROOT/$path_candidate" ]]; then
                             SOURCE_CODE_FILES_FROM_MD+=("$REPO_ROOT/$path_candidate")
                        elif [[ -f "$path_candidate" ]]; then
                            SOURCE_CODE_FILES_FROM_MD+=("$path_candidate")
                        fi
                    fi
                fi
            fi
        done < "$md_file"

        if [[ ${#SOURCE_CODE_FILES_FROM_MD[@]} -eq 0 ]]; then
            log_warning "No source files found in $md_file. Analyzing without source."
        fi

        process_analysis_file "$(basename "$md_file")" "${SOURCE_CODE_FILES_FROM_MD[@]}"
    done

else
    # --- Single File Mode ---
    log_info "Mode: Single file."
    TARGET_FILE_ARG="$1"
    shift
    SOURCE_FILES=("$@")
    process_analysis_file "$TARGET_FILE_ARG" "${SOURCE_FILES[@]}"
fi

log_info "=================================================="
log_success "Script finished. Handing over to AI for analysis."
log_info "AI should now:"
log_info "  1. Read constitution.md for analysis rules."
log_info "  2. Analyze source files and update the target .md file(s)."
log_info "  3. Update the quality checklist within each .md file."
log_info "  4. AI will then need to calculate and update the quality level in overview.md."

