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

# --- Parse Arguments ---
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [ "$#" -lt 1 ]; then
    log_error "Error: Insufficient arguments." >&2
    show_help >&2
    exit 1
fi

TARGET_FILE_ARG="$1"
shift
SOURCE_FILES=("$@")

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1

if [[ ! -d "$TOPIC_DIR" ]]; then
    log_error "Topic directory not found: $TOPIC_DIR" >&2
    log_error "Run /analysis.init first." >&2
    exit 1
fi

# --- Resolve Target File Path ---
# The target file might be:
# 1. Relative to TOPIC_DIR (e.g., "features/001-login.md")
# 2. In SHARED_DIR (e.g., "components/001-button.md")
# 3. Just filename without extension (e.g., "server")

TARGET_FILE_NAME=$(basename "$TARGET_FILE_ARG" .md)
TARGET_FILE=""
OVERVIEW_FILE="$TOPIC_DIR/overview.md"

# Potential directories within the topic
SEARCH_DIRS=(
    "$TOPIC_DIR"
    "$TOPIC_DIR/features"
    "$TOPIC_DIR/apis"
    "$TOPIC_DIR/helpers"
    "$TOPIC_DIR/request-pipeline"
)

# Search for the target file
for dir in "${SEARCH_DIRS[@]}"; do
    if [[ -f "$dir/$TARGET_FILE_ARG" ]]; then
        TARGET_FILE="$dir/$TARGET_FILE_ARG"
        break
    elif [[ -f "$dir/${TARGET_FILE_ARG}.md" ]]; then
        TARGET_FILE="$dir/${TARGET_FILE_ARG}.md"
        break
    fi
done

if [[ -z "$TARGET_FILE" ]]; then
    log_error "Target file not found: $TARGET_FILE_ARG" >&2
    log_error "Searched in:" >&2
    for dir in "${SEARCH_DIRS[@]}"; do
        log_error "  - $dir" >&2
    done
    exit 1
fi

log_success "Found target file: $TARGET_FILE"

# --- Determine Overview File ---
if [[ ! -f "$OVERVIEW_FILE" ]]; then
    log_error "Overview file not found: $OVERVIEW_FILE" >&2
    exit 1
fi

# --- Validate Source Files ---
if [[ ${#SOURCE_FILES[@]} -gt 0 ]]; then
    for source_file in "${SOURCE_FILES[@]}"; do
        if [[ ! -f "$source_file" ]]; then
            log_warning "Source file not found: $source_file"
        fi
    done
fi

# --- Categorize Files by Type ---
VIEW_FILES=()
CONTROLLER_FILES=()
SERVICE_FILES=()
UTILITY_FILES=()
OTHER_FILES=()

for file_path in "${SOURCE_FILES[@]}"; do
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
            elif [[ $file_path == */api/* || $file_path == */routes/* ]]; then
                CONTROLLER_FILES+=("$file_path")  # API routes treated as controllers
            else
                OTHER_FILES+=("$file_path")
            fi
            ;;
        vue)
            COMPONENT_FILES+=("$file_path")
            ;;
        *)
            OTHER_FILES+=("$file_path")
            ;;
    esac
done

# --- Environment Validation Passed ---
log_success "Environment validation passed"
log_info "Target file: $(basename "$TARGET_FILE")"
log_info "Overview file: $(basename "$OVERVIEW_FILE")"

if [[ ${#SOURCE_FILES[@]} -gt 0 ]]; then
    log_info ""
    log_info "Source files categorized:"
    [[ ${#VIEW_FILES[@]} -gt 0 ]] && log_info "  Views: ${VIEW_FILES[*]}"
    [[ ${#CONTROLLER_FILES[@]} -gt 0 ]] && log_info "  Controllers: ${CONTROLLER_FILES[*]}"
    [[ ${#SERVICE_FILES[@]} -gt 0 ]] && log_info "  Services: ${SERVICE_FILES[*]}"
    [[ ${#UTILITY_FILES[@]} -gt 0 ]] && log_info "  Utilities: ${UTILITY_FILES[*]}"
    [[ ${#OTHER_FILES[@]} -gt 0 ]] && log_info "  Other: ${OTHER_FILES[*]}"
fi

log_info ""
log_info "AI should now:"
log_info "  1. Read constitution.md for analysis rules"
log_info "  2. Analyze source files and update $TARGET_FILE"
log_info "  3. Fill [待補充] placeholders with concrete content"
log_info "  4. Add Mermaid diagrams, code snippets, and explanations"
log_info "  5. Update quality checklist at the end of the file"
log_info ""
log_info "After AI completes analysis, this script will:"
log_info "  - Calculate quality level based on checklist completion"
log_info "  - Update overview.md with new quality level"

# --- Store paths for AI to use ---
echo ""
echo "=== Environment Variables for AI ==="
echo "TARGET_FILE='$TARGET_FILE'"
echo "OVERVIEW_FILE='$OVERVIEW_FILE'"
echo "CONSTITUTION_FILE='$CONSTITUTION_FILE'"
echo ""

# Note: Quality calculation will be done AFTER AI updates the file
# The AI should update the file content and check items in the quality checklist
# Then we can run this script again or have AI call a separate function to:
#   1. Count checked items in quality checklist
#   2. Calculate percentage
#   3. Determine quality level
#   4. Update overview.md

log_info "=== Post-Analysis Tasks (to be done after AI updates) ==="
log_info "After AI completes the analysis:"
log_info ""
log_info "# Calculate quality level"
log_info "PERCENTAGE=\$(count_checked_items '$TARGET_FILE')"
log_info "QUALITY_LEVEL=\$(calculate_quality_level \$PERCENTAGE)"
log_info ""
log_info "# Update overview.md"
log_info "update_quality_level '$OVERVIEW_FILE' '$(basename "$TARGET_FILE")' \"\$QUALITY_LEVEL\""
log_info ""
log_info "# Report results"
log_info "echo \"Quality level updated: \$QUALITY_LEVEL (\${PERCENTAGE}% complete)\""

