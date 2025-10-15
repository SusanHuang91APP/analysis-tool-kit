#!/usr/bin/env bash
#
# Initialize analysis environment with branch and directory structure.
# This script only creates the environment, no file analysis.
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# --- Parse Arguments ---
JSON_MODE=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] <analysis_name>"
            echo "Example: $0 \"Sale Page Analysis\""
            echo "Options:"
            echo "  --json    Output result in JSON format"
            exit 0 
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

ANALYSIS_NAME="${ARGS[*]}"

# Parse JSON if the input looks like JSON
if [[ "$ANALYSIS_NAME" =~ ^\{.*\}$ ]]; then
    # Extract analysis_name from JSON using grep and sed
    ANALYSIS_NAME=$(echo "$ANALYSIS_NAME" | grep -o '"analysis_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"analysis_name"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
fi

if [ -z "$ANALYSIS_NAME" ]; then
    log_error "Usage: $0 [--json] <analysis_name>" >&2
    log_error "Example: $0 \"Sale Page Analysis\"" >&2
    exit 1
fi

# --- Validate Requirements ---
if ! validate_requirements; then
    exit 1
fi

# --- Get Paths ---
eval $(get_analysis_paths)
ANALYSIS_PARENT_DIR="$KIT_PARENT_DIR/analysis"

# --- Create Analysis Environment ---
log_info "Initializing analysis environment for '$ANALYSIS_NAME'..."

# Use the enhanced feature creation utilities
RESULT=$(create_feature_environment "analysis" "$ANALYSIS_NAME" "$ANALYSIS_PARENT_DIR" "")

# Extract results
eval "$RESULT"

# Only copy README template for now
log_info "Setting up basic structure..."
cp "$KIT_DIR/templates/readme-template.md" "$FEATURE_DIR/README.md"

# Update template placeholders with specific analysis details
log_info "Populating README.md with analysis details..."
ANALYSIS_NUM=$(echo "$DIR_NAME" | cut -d'-' -f1)
TOPIC_NAME_SLUG=$(echo "$DIR_NAME" | sed 's/^[0-9]*-//')
CURRENT_DATE=$(date +%Y-%m-%d)
INITIAL_STATUS="📝 框架建立 ⭐"
README_FILE="$FEATURE_DIR/README.md"

# Using sed -i.bak for cross-platform compatibility (macOS/Linux)
# The order of replacement is important to avoid conflicts with placeholders
sed -i.bak \
    -e "s/\[頁面名稱\]/$ANALYSIS_NAME/g" \
    -e "s|Git 分支: analysis/\[###\]-\[topic-name\]|Git 分支: $BRANCH_NAME|g" \
    -e "s|\[###\]-\[topic-name\]/|$DIR_NAME/|g" \
    -e "s/\[###\]/$ANALYSIS_NUM/g" \
    -e "s/\[topic-name\]/$ANALYSIS_NAME/g" \
    -e "s/\[YYYY-MM-DD\]/$CURRENT_DATE/g" \
    -e "s/\[階段狀態\]/$INITIAL_STATUS/g" \
    "$README_FILE"

# Clean up backup files created by sed
rm "${README_FILE}.bak"

log_success "Successfully initialized analysis environment for '$ANALYSIS_NAME'."
log_info "Next step: Use /analysis-create <files...> to create architecture analysis."

# Output results
if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","ANALYSIS_DIR":"%s","DIR_NAME":"%s"}\n' \
           "$BRANCH_NAME" "$FEATURE_DIR" "$DIR_NAME"
else
    echo "Analysis environment for '$ANALYSIS_NAME' is ready:"
    echo "  Branch: $BRANCH_NAME"
    echo "  Directory: $FEATURE_DIR"
    echo "  Files: README.md"
fi
