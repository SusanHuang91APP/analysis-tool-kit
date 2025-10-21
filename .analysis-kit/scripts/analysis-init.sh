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
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] <topic_name>"
            echo "Example: $0 \"會員管理功能\""
            echo "Options:"
            echo "  --json    Output result in JSON format"
            exit 0 
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

TOPIC_NAME="${ARGS[*]}"

# Parse JSON if the input looks like JSON
if [[ "$TOPIC_NAME" =~ ^\{.*\}$ ]]; then
    # Extract topic_name from JSON using grep and sed
    TOPIC_NAME=$(echo "$TOPIC_NAME" | grep -o '"topic_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"topic_name"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
fi

if [ -z "$TOPIC_NAME" ]; then
    log_error "Usage: $0 [--json] <topic_name>" >&2
    log_error "Example: $0 \"會員管理功能\"" >&2
    exit 1
fi

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
log_info "Initializing Topic environment for '$TOPIC_NAME'..."

# Use the enhanced feature creation utilities
RESULT=$(create_feature_environment "analysis" "$TOPIC_NAME" "$ANALYSIS_BASE_DIR" "")

# Extract results
eval "$RESULT"

# --- Create Topic Structure ---
log_info "Setting up Topic structure..."

# Create subdirectories
mkdir -p "$FEATURE_DIR/features"
mkdir -p "$FEATURE_DIR/apis"

# Extract topic number and name
TOPIC_NUM=$(echo "$DIR_NAME" | grep -o '^[0-9]\+')
TOPIC_NAME_SLUG=$(echo "$DIR_NAME" | sed 's/^[0-9]*-//')
CURRENT_DATE=$(date +%Y-%m-%d)

# --- Create server.md from template ---
SERVER_TEMPLATE="$TEMPLATES_DIR/server-template.md"
if [[ -f "$SERVER_TEMPLATE" ]]; then
    cp "$SERVER_TEMPLATE" "$FEATURE_DIR/server.md"
    sed -i.bak \
        -e "s/\[###\]/$TOPIC_NUM/g" \
        -e "s/\[topic-name\]/$TOPIC_NAME/g" \
        -e "s/\[頁面名稱\]/$TOPIC_NAME/g" \
        "$FEATURE_DIR/server.md"
    rm -f "$FEATURE_DIR/server.md.bak"
    log_success "Created server.md"
else
    log_warning "Server template not found: $SERVER_TEMPLATE"
fi

# --- Create client.md from template ---
CLIENT_TEMPLATE="$TEMPLATES_DIR/client-template.md"
if [[ -f "$CLIENT_TEMPLATE" ]]; then
    cp "$CLIENT_TEMPLATE" "$FEATURE_DIR/client.md"
    sed -i.bak \
        -e "s/\[###\]/$TOPIC_NUM/g" \
        -e "s/\[topic-name\]/$TOPIC_NAME/g" \
        -e "s/\[頁面名稱\]/$TOPIC_NAME/g" \
        "$FEATURE_DIR/client.md"
    rm -f "$FEATURE_DIR/client.md.bak"
    log_success "Created client.md"
else
    log_warning "Client template not found: $CLIENT_TEMPLATE"
fi

# --- Create Topic overview.md ---
OVERVIEW_TEMPLATE="$TEMPLATES_DIR/overview-template.md"
OVERVIEW_FILE="$FEATURE_DIR/overview.md"

if [[ -f "$OVERVIEW_TEMPLATE" ]]; then
    cp "$OVERVIEW_TEMPLATE" "$OVERVIEW_FILE"
    
    # Update template placeholders
    sed -i.bak \
        -e "s/\[Topic Name\]/$TOPIC_NAME/g" \
        -e "s/\[YYYY-MM-DD\]/$CURRENT_DATE/g" \
        -e "s/\[###\]/$TOPIC_NUM/g" \
        "$OVERVIEW_FILE"
    rm -f "${OVERVIEW_FILE}.bak"
    
    # Register server.md and client.md in overview.md
    # Find the table marker and add entries
    local table_marker="|------|----------|"
    if grep -q "$table_marker" "$OVERVIEW_FILE"; then
        sed -i.bak "/$table_marker/a\\
| [server.md](./server.md) | 📝 待分析 |\\
| [client.md](./client.md) | 📝 待分析 |
" "$OVERVIEW_FILE"
        rm -f "${OVERVIEW_FILE}.bak"
    fi
    
    log_success "Created overview.md with registered files"
else
    log_warning "Overview template not found: $OVERVIEW_TEMPLATE"
fi

log_success "Successfully initialized Topic environment for '$TOPIC_NAME'."
log_info "Next step: Use /analysis.create <type> [source-files...] to create analysis files."

# --- Output Results ---
if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","TOPIC_DIR":"%s","DIR_NAME":"%s"}\n' \
           "$BRANCH_NAME" "$FEATURE_DIR" "$DIR_NAME"
else
    echo ""
    echo "Topic environment for '$TOPIC_NAME' is ready:"
    echo "  Branch: $BRANCH_NAME"
    echo "  Directory: $FEATURE_DIR"
    echo "  Files:"
    echo "    - overview.md (tracking manifest)"
    echo "    - server.md (backend analysis)"
    echo "    - client.md (frontend analysis)"
    echo "    - features/ (empty)"
    echo "    - apis/ (empty)"
    echo ""
    echo "Shared structure:"
    echo "  - $SHARED_DIR/overview.md"
    echo "  - $SHARED_DIR/request-pipeline/"
    echo "  - $SHARED_DIR/components/"
    echo "  - $SHARED_DIR/helpers/"
fi

