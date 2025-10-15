#!/usr/bin/env bash
#
# Update analysis content by adding files to existing blocks.
# This script validates environment and categorizes files - AI does the actual analysis.
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
eval $(get_analysis_paths)

show_help() {
    echo "Usage: $0 \"target_analysis_file\" <source_file_1> [<source_file_2>...]"
    echo ""
    echo "Description:"
    echo "  Update an existing analysis file (view-*.md, server-*.md, etc.) with detailed"
    echo "  information extracted from the provided source code files."
    echo ""
    echo "Arguments:"
    echo "  \"target_analysis_file\"  The name of the .md file to update (e.g., \"view-01-some-feature\")."
    echo "                          Must be an existing file in the analysis directory."
    echo "  <source_file>           Path to the source code file(s) to analyze."
    echo ""
    echo "Example:"
    echo "  $0 \"view-01-user-profile\" Controllers/UserController.cs Services/UserService.cs"
}

# --- Parse Arguments ---
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [ "$#" -lt 2 ]; then
    log_error "Error: Insufficient arguments." >&2
    show_help >&2
    exit 1
fi

TARGET_BLOCK="$1"
shift
FILES_TO_ANALYZE=("$@")

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1

if [[ ! -d "$PAGE_ANALYSIS_DIR" ]]; then
    log_error "Analysis directory not found: $PAGE_ANALYSIS_DIR" >&2
    log_error "Run /analysis-init first." >&2
    exit 1
fi

# Check for architecture.md or overview.md (backward compatible)
ARCH_FILE="$PAGE_ANALYSIS_DIR/architecture.md"
if [[ ! -f "$ARCH_FILE" ]]; then
    ARCH_FILE="$PAGE_ANALYSIS_DIR/overview.md"
    if [[ ! -f "$ARCH_FILE" ]]; then
        log_error "architecture.md not found. Run /analysis-create-architecture first." >&2
        exit 1
    fi
fi

# --- Validate Target Block ---
# The target block name in README might not have .md, but the file on disk does.
# We accept the name with or without .md for user convenience.
TARGET_BLOCK_NAME=$(basename "$TARGET_BLOCK" .md)
TARGET_BLOCK_FILE="$PAGE_ANALYSIS_DIR/${TARGET_BLOCK_NAME}.md"

if [[ ! -f "$TARGET_BLOCK_FILE" ]]; then
    log_error "Target analysis file not found: $TARGET_BLOCK_FILE" >&2
    log_error "Please ensure the name matches an existing analysis file." >&2
    log_error "Available analysis files:" >&2
    ls "$PAGE_ANALYSIS_DIR"/*.md 2>/dev/null | grep -E '(view|component|page|server|service-)-' | sed 's#.*/##' || echo "  No analysis files found." >&2
    exit 1
fi

# --- Validate Source Files ---
for file_path in "${FILES_TO_ANALYZE[@]}"; do
    if [[ ! -f "$file_path" ]]; then 
        log_error "Source file not found: ${file_path}" >&2
        exit 1
    fi
done

# --- Categorize Files by Type ---
VIEW_FILES=()
CONTROLLER_FILES=()
SERVICE_FILES=()
UTILITY_FILES=()
OTHER_FILES=()

for file_path in "${FILES_TO_ANALYZE[@]}"; do
    case "${file_path##*.}" in
        cshtml|html)
            VIEW_FILES+=("$file_path")
            ;;
        cs)
            if [[ $file_path == *Controller.cs ]]; then
                CONTROLLER_FILES+=("$file_path")
            elif [[ $file_path == *Service.cs ]]; then
                SERVICE_FILES+=("$file_path")
            else
                OTHER_FILES+=("$file_path")
            fi
            ;;
        ts|tsx|js|jsx)
            if [[ $file_path == *Controller.ts || $file_path == *Controller.tsx ]]; then
                CONTROLLER_FILES+=("$file_path")
            elif [[ $file_path == *Service.ts || $file_path == *Service.tsx ]]; then
                SERVICE_FILES+=("$file_path")
            elif [[ $file_path == *Utility.ts || $file_path == *Utility.tsx ]]; then
                UTILITY_FILES+=("$file_path")
            elif [[ $file_path == */api/* || $file_path == */routes/* ]]; then
                CONTROLLER_FILES+=("$file_path")  # API routes treated as controllers
            else
                OTHER_FILES+=("$file_path")
            fi
            ;;
        vue)
            OTHER_FILES+=("$file_path")
            ;;
        *)
            OTHER_FILES+=("$file_path")
            ;;
    esac
done

# --- Environment Validation Passed ---
log_success "Environment validation passed"
log_info "Analysis directory: $PAGE_ANALYSIS_DIR"
log_info "Architecture file: $(basename $ARCH_FILE)"
log_info "Target file:        $(basename "$TARGET_BLOCK_FILE")"

log_info ""
log_info "Source files categorized:"
[[ ${#VIEW_FILES[@]} -gt 0 ]] && log_info "  Views: ${VIEW_FILES[*]}"
[[ ${#CONTROLLER_FILES[@]} -gt 0 ]] && log_info "  Controllers: ${CONTROLLER_FILES[*]}"
[[ ${#SERVICE_FILES[@]} -gt 0 ]] && log_info "  Services: ${SERVICE_FILES[*]}"
[[ ${#UTILITY_FILES[@]} -gt 0 ]] && log_info "  Utilities: ${UTILITY_FILES[*]}"
[[ ${#OTHER_FILES[@]} -gt 0 ]] && log_info "  Other: ${OTHER_FILES[*]}"
log_info ""
log_info "AI will now analyze the files and update the appropriate analysis documents."
