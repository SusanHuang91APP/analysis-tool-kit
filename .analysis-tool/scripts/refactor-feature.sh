#!/usr/bin/env bash
#
# Generate refactor-###-*.md from view-*.md files
# This script validates environment and detects view files.
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
eval $(get_analysis_paths)

# --- Parse Arguments ---
SPECIFIED_FILES=()
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: $0 [file1] [file2...]"
            echo ""
            echo "Description:"
            echo "  Generate refactor-###-*.md from view analysis files"
            echo ""
            echo "Arguments:"
            echo "  [file]   Optional: specific view-*.md or component-*.md files to analyze"
            echo "           If not provided, all view-*.md files will be used"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 view-01-xxx.md view-02-xxx.md"
            echo "  $0 component-01-xxx.md"
            exit 0
            ;;
        *)
            SPECIFIED_FILES+=("$arg")
            ;;
    esac
done

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1

if [[ ! -d "$PAGE_ANALYSIS_DIR" ]]; then
    log_error "Analysis directory not found: $PAGE_ANALYSIS_DIR"
    log_error "Run /analysis-init first."
    exit 1
fi

# --- Determine which view files to use ---
if [[ ${#SPECIFIED_FILES[@]} -gt 0 ]]; then
    # Use specified files
    VIEW_FILES=()
    for file in "${SPECIFIED_FILES[@]}"; do
        # Check if file is relative or absolute
        if [[ "$file" = /* ]]; then
            # Absolute path
            if [[ -f "$file" ]]; then
                VIEW_FILES+=("$file")
            else
                log_error "Specified file not found: $file"
                exit 1
            fi
        else
            # Relative path, prepend PAGE_ANALYSIS_DIR
            full_path="$PAGE_ANALYSIS_DIR/$file"
            if [[ -f "$full_path" ]]; then
                VIEW_FILES+=("$full_path")
            else
                log_error "Specified file not found: $full_path"
                exit 1
            fi
        fi
    done
    log_info "Using specified files: ${#VIEW_FILES[@]}"
else
    # Find all view-*.md files
    VIEW_FILES=($(find "$PAGE_ANALYSIS_DIR" -name "view-*.md" -o -name "component-*.md" -type f | sort))
    
    if [[ ${#VIEW_FILES[@]} -eq 0 ]]; then
        log_error "No view-*.md or component-*.md files found in: $PAGE_ANALYSIS_DIR"
        log_error "Run /analysis-create first to create view analysis files."
        exit 1
    fi
fi

# --- Check which output files exist ---
EXISTING_FILES=()
NEW_FILES=()

for file in "${VIEW_FILES[@]}"; do
    basename_file=$(basename "$file")
    refactor_file=$(echo "$basename_file" | sed 's/^view-/refactor-/' | sed 's/^component-/refactor-/')
    refactor_path="$PAGE_ANALYSIS_DIR/$refactor_file"
    
    if [[ -f "$refactor_path" ]]; then
        EXISTING_FILES+=("$refactor_file")
    else
        NEW_FILES+=("$refactor_file")
    fi
done

# --- Validation passed ---
log_success "Environment validation passed"
log_info "Analysis directory: $PAGE_ANALYSIS_DIR"
log_info "View files found: ${#VIEW_FILES[@]}"
log_info "Existing refactor files: ${#EXISTING_FILES[@]} (will UPDATE)"
log_info "New refactor files: ${#NEW_FILES[@]} (will CREATE)"
log_info ""

# Output paths for AI to use
echo "PAGE_ANALYSIS_DIR='$PAGE_ANALYSIS_DIR'"
echo "VIEW_FILES_COUNT=${#VIEW_FILES[@]}"
echo "EXISTING_COUNT=${#EXISTING_FILES[@]}"
echo "NEW_COUNT=${#NEW_FILES[@]}"

# List view files
echo "VIEW_FILES=("
for file in "${VIEW_FILES[@]}"; do
    echo "  '$file'"
done
echo ")"

# List existing files that will be updated
if [[ ${#EXISTING_FILES[@]} -gt 0 ]]; then
    echo "EXISTING_REFACTOR_FILES=("
    for file in "${EXISTING_FILES[@]}"; do
        echo "  '$file'"
    done
    echo ")"
fi

# List new files that will be created
if [[ ${#NEW_FILES[@]} -gt 0 ]]; then
    echo "NEW_REFACTOR_FILES=("
    for file in "${NEW_FILES[@]}"; do
        echo "  '$file'"
    done
    echo ")"
fi

log_info ""
if [[ ${#EXISTING_FILES[@]} -gt 0 ]] && [[ ${#NEW_FILES[@]} -gt 0 ]]; then
    log_info "AI will UPDATE ${#EXISTING_FILES[@]} and CREATE ${#NEW_FILES[@]} refactor files based on:"
elif [[ ${#EXISTING_FILES[@]} -gt 0 ]]; then
    log_info "AI will UPDATE ${#EXISTING_FILES[@]} existing refactor files based on:"
else
    log_info "AI will CREATE ${#NEW_FILES[@]} new refactor files based on:"
fi
log_info "  - view-*.md files (前端視圖分析)"
log_info "  - feature-refactor-template.md (功能重構範本)"
log_info "  - refactor-constitution.md (重構憲法)"
log_info ""
log_info "Output files:"
for file in "${VIEW_FILES[@]}"; do
    basename_file=$(basename "$file")
    refactor_file=$(echo "$basename_file" | sed 's/^view-/refactor-/' | sed 's/^component-/refactor-/')
    refactor_path="$PAGE_ANALYSIS_DIR/$refactor_file"
    
    if [[ -f "$refactor_path" ]]; then
        log_info "  - $refactor_file (UPDATE)"
    else
        log_info "  - $refactor_file (CREATE)"
    fi
done
