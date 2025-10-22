#!/usr/bin/env bash
#
# Initialize analysis environment for V2 architecture
# Creates Topic directory with standard structure and shared/ if needed
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# --- Parse Arguments ---
JSON_MODE=false
TOPIC_SLUG=""
TOPIC_TITLE=""

ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h)
            echo "Usage: $0 [--json] <topic_slug> [\"<topic_title>\"]"
            echo "Example: $0 trades-order-detail \"訂單明細\""
            echo "Options:"
            echo "  --json    Output result in JSON format"
            exit 0
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

if [ ${#ARGS[@]} -lt 1 ]; then
    log_error "Usage: $0 [--json] <topic_slug> [\"<topic_title>\"]" >&2
    log_error "Example: $0 trades-order-detail \"訂單明細\"" >&2
    exit 1
fi

TOPIC_SLUG="${ARGS[0]}"
TOPIC_TITLE="${ARGS[1]:-$TOPIC_SLUG}" # Default title to slug if not provided

# --- Validate Requirements ---
if ! validate_requirements; then
    exit 1
fi

# --- Get Paths ---
eval $(get_analysis_paths)

# --- Create Shared Structure (First Time) ---
if [[ ! -d "$SHARED_DIR" ]]; then
    log_info "First-time initialization: Creating shared/ structure..."
    ensure_shared_structure "$SHARED_DIR" "$TEMPLATES_DIR"
fi

# --- Create Topic Environment ---
log_info "Initializing Topic environment for '$TOPIC_SLUG' ($TOPIC_TITLE)..."

# Use the enhanced feature creation utilities
RESULT=$(create_feature_environment "analysis" "$TOPIC_SLUG" "$ANALYSIS_BASE_DIR" "")

# Extract results
eval "$RESULT"

# --- Create Topic Structure ---
log_info "Setting up Topic structure..."

# Create subdirectories
mkdir -p "$FEATURE_DIR/features"
mkdir -p "$FEATURE_DIR/apis"

TOPIC_NUM=$(echo "$DIR_NAME" | grep -o '^[0-9]\+')
TOPIC_NAME_SLUG=$(echo "$DIR_NAME" | sed 's/^[0-9]*-//')
CURRENT_DATE=$(date +%Y-%m-%d)

# --- Create Topic overview.md ---
OVERVIEW_TEMPLATE="$TEMPLATES_DIR/overview-template.md"
OVERVIEW_FILE="$FEATURE_DIR/overview.md"

if [[ -f "$OVERVIEW_TEMPLATE" ]]; then
    cp "$OVERVIEW_TEMPLATE" "$OVERVIEW_FILE"
    
    # Update template placeholders
    sed -i.bak \
        -e "s/__TOPIC_NAME__/$TOPIC_TITLE/g" \
        -e "s/__CURRENT_DATE__/$CURRENT_DATE/g" \
        "$OVERVIEW_FILE"
    rm -f "${OVERVIEW_FILE}.bak"
    
    log_success "Created overview.md"
else
    log_warning "Overview template not found: $OVERVIEW_TEMPLATE"
fi

log_success "Successfully initialized Topic environment for '$TOPIC_SLUG'."
log_info "Next step: Use /analysis.create <type> [source-files...] to create analysis files."

# --- Output Results ---
if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","TOPIC_DIR":"%s","DIR_NAME":"%s"}\n' \
           "$BRANCH_NAME" "$FEATURE_DIR" "$DIR_NAME"
else
    echo ""
    echo "Topic environment for '$TOPIC_SLUG' ('$TOPIC_TITLE') is ready:"
    echo "  Branch: $BRANCH_NAME"
    echo "  Directory: $FEATURE_DIR"
    echo "  Files:"
    echo "    - overview.md (tracking manifest)"
    echo "    - features/ (empty)"
    echo "    - apis/ (empty)"
    echo ""
    echo "Shared structure:"
    echo "  - $SHARED_DIR/overview.md"
    echo "  - $SHARED_DIR/request-pipeline/"
    echo "  - $SHARED_DIR/components/"
    echo "  - $SHARED_DIR/helpers/"
fi

