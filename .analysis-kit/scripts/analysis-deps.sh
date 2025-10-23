#!/usr/bin/env bash
#
# Update dependencies for one or all analysis files in the current topic.
# Scans source code and links to existing analysis files.
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
eval $(get_analysis_paths)

show_help() {
    echo "Usage: $0 [target_file.md]"
    echo ""
    echo "Description:"
    echo "  Updates the 'Dependencies' section of analysis files."
    echo "  It analyzes the source code files listed in the markdown,"
    echo "  identifies dependencies, and links to existing analysis files."
    echo ""
    echo "Arguments:"
    echo "  [target_file.md]   Optional. The specific .md file to update."
    echo "                     If omitted, all files in the current topic's"
    echo "                     overview.md will be processed."
    echo ""
    echo "Examples:"
    echo "  # Update a single feature file"
    echo "  $0 analysis/001-trades-order-detail/features/001-some-feature.md"
    echo ""
    echo "  # Update all files in the current topic"
    echo "  $0"
}

# --- Argument Parsing ---
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

TARGET_MD_ARG=""
if [ -n "$1" ]; then
    TARGET_MD_ARG="$1"
    shift
fi
SOURCE_FILES_TO_ADD=("$@")

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1
if [[ ! -d "$TOPIC_DIR" ]]; then
    log_error "Topic directory not found: $TOPIC_DIR" >&2
    log_error "Run /analysis.init first or switch to an analysis branch." >&2
    exit 1
fi
OVERVIEW_FILE="$TOPIC_DIR/overview.md"
if [[ ! -f "$OVERVIEW_FILE" ]]; then
    log_error "Overview file not found: $OVERVIEW_FILE" >&2
    exit 1
fi

# --- Find existing analysis files for linking ---
EXISTING_ANALYSIS_FILES=()
while IFS= read -r file; do
    EXISTING_ANALYSIS_FILES+=("$file")
done < <(find "$TOPIC_DIR" -type f -name "*.md" ! -name "overview.md")
log_info "Found ${#EXISTING_ANALYSIS_FILES[@]} existing analysis files to use for linking."

# --- Determine target files to process ---
TARGET_MD_FILES=()
if [ -n "$TARGET_MD_ARG" ]; then
    # Single file mode
    if [[ ! -f "$TARGET_MD_ARG" ]]; then
        log_error "Target file not found: $TARGET_MD_ARG" >&2
        exit 1
    fi
    TARGET_MD_FILES+=("$TARGET_MD_ARG")
    log_info "Mode: Single file. Processing '$TARGET_MD_ARG'."
else
    # Batch mode
    log_info "Mode: Batch. Processing all files from $OVERVIEW_FILE."
    # Extract relative paths from overview.md, e.g., [features/001-login](./features/001-login.md)
    RELATIVE_PATHS=()
    while IFS= read -r path; do
        RELATIVE_PATHS+=("$path")
    done < <(grep -o '(\./[^)]*\.md)' "$OVERVIEW_FILE" | sed 's/[()]//g')
    for rel_path in "${RELATIVE_PATHS[@]}"; do
        full_path="$TOPIC_DIR/${rel_path#./}"
        if [[ -f "$full_path" ]]; then
            TARGET_MD_FILES+=("$full_path")
        else
            log_warning "File listed in overview.md not found: $full_path"
        fi
    done
fi

if [[ ${#TARGET_MD_FILES[@]} -eq 0 ]]; then
    log_warning "No target files to process."
    exit 0
fi

# --- Add new source files to markdown if provided ---
if [[ ${#SOURCE_FILES_TO_ADD[@]} -gt 0 ]]; then
    if [[ ${#TARGET_MD_FILES[@]} -ne 1 ]]; then
        log_error "Error: Providing source files is only supported in single file mode." >&2
        exit 1
    fi
    
    target_md_file_to_update="${TARGET_MD_FILES[0]}"
    log_info "Adding ${#SOURCE_FILES_TO_ADD[@]} source file(s) to '$target_md_file_to_update'..."

    temp_file=$(mktemp)
    
    in_section=false
    section_ended=false
    
    # Read the file and insert new source files
    while IFS= read -r line; do
        if [[ "$line" =~ ^"### 1.1 📂 分析檔案資訊" ]]; then
            in_section=true
        elif $in_section && [[ "$line" =~ ^"###" ]]; then
            in_section=false
            section_ended=true
            # Add new source files before the next section starts
            for new_source in "${SOURCE_FILES_TO_ADD[@]}"; do
                 # Check for duplicates before adding
                if ! grep -q "|$new_source|" "$target_md_file_to_update"; then
                    echo "| $new_source |" >> "$temp_file"
                    log_success "Added: $new_source"
                else
                    log_warning "Skipped (already exists): $new_source"
                fi
            done
        fi
        echo "$line" >> "$temp_file"
    done < "$target_md_file_to_update"

    # If the section was found and ended, move the temp file
    if [[ "$section_ended" = true ]]; then
        mv "$temp_file" "$target_md_file_to_update"
    else
        log_error "Could not find the '### 1.1 📂 分析檔案資訊' section in '$target_md_file_to_update'." >&2
        rm "$temp_file"
        exit 1
    fi
fi

log_success "Found ${#TARGET_MD_FILES[@]} markdown file(s) to process."
echo ""

# --- Process each target file ---
for md_file in "${TARGET_MD_FILES[@]}"; do
    log_info "--------------------------------------------------"
    log_info "Processing: $(basename "$md_file")"

    # Extract source code file paths from the markdown file
    # Looks for lines between "### 1.1 📂 分析檔案資訊" and the next "###"
    SOURCE_CODE_FILES=()
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
            # Extract path-like strings, assuming they are between '|' and '|'
            if [[ "$line" =~ \|([^|]+)\| ]]; then
                path_candidate=$(echo "${BASH_REMATCH[1]}" | xargs) # Trim whitespace
                # A simple check to see if it looks like a file path
                if [[ "$path_candidate" =~ \. ]]; then
                    # Check if the file exists relative to the repo root
                    if [[ -f "$REPO_ROOT/$path_candidate" ]]; then
                         SOURCE_CODE_FILES+=("$REPO_ROOT/$path_candidate")
                    elif [[ -f "$path_candidate" ]]; then
                        SOURCE_CODE_FILES+=("$path_candidate")
                    else
                        # A placeholder or a file that doesn't exist
                        :
                    fi
                fi
            fi
        fi
    done < "$md_file"

    if [[ ${#SOURCE_CODE_FILES[@]} -eq 0 ]]; then
        log_warning "No source code files found in '$md_file'. Skipping."
        continue
    fi

    log_success "Found ${#SOURCE_CODE_FILES[@]} source file(s) to analyze for dependencies."
    
    # Prepare for AI
    echo ""
    echo "=== Environment for AI: $(basename "$md_file") ==="
    echo "TARGET_MD_FILE='$md_file'"
    echo "SOURCE_CODE_FILES='${SOURCE_CODE_FILES[*]}'"
    
    # Pass existing analysis files as a flat string to avoid complexity
    EXISTING_FILES_STRING=""
    for f in "${EXISTING_ANALYSIS_FILES[@]}"; do
        EXISTING_FILES_STRING+="$f;"
    done
    echo "EXISTING_ANALYSIS_FILES='$EXISTING_FILES_STRING'"
    
    echo ""
    echo "AI Task: Please analyze the dependencies for the source files and update the markdown file."
    echo "1. Read the source files: ${SOURCE_CODE_FILES[*]}"
    echo "2. Identify all dependencies (imports, injections, etc.)."
    echo "3. Cross-reference dependencies with the list of existing analysis files."
    echo "4. Generate a new markdown table for the '依賴關係 (Dependencies)' section."
    echo "5. If a dependency matches an existing analysis file, create a relative link to it."
    echo "6. Edit '$md_file' to replace the content under '### 1.2 📦 依賴關係 (Dependencies)' with the new table."
    echo "================================================"
    echo ""
done

log_info "Script finished. Handing over to AI for analysis and file updates."
