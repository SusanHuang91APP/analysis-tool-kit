#!/usr/bin/env bash
#
# Create a new feature with branch, directory structure, and template
# Extracted and enhanced from spec-kit's create-new-feature.sh
# 
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# --- Parse Arguments ---
JSON_MODE=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] <feature_description>"
            echo "Example: $0 \"User Authentication System\""
            echo "Options:"
            echo "  --json    Output result in JSON format"
            echo "  --help    Show this help message"
            exit 0 
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    log_error "Usage: $0 [--json] <feature_description>" >&2
    log_error "Example: $0 \"User Authentication System\"" >&2
    exit 1
fi

# --- Validate Requirements ---
if ! validate_requirements; then
    exit 1
fi

# --- Setup Paths ---
REPO_ROOT=$(get_repo_root)
SPECS_DIR="$REPO_ROOT/specs"

# Ensure specs directory exists
validate_directory_structure "$SPECS_DIR"

# --- Create Feature Environment ---
log_info "Creating feature environment for '$FEATURE_DESCRIPTION'..."

# Create the feature using our enhanced utilities
RESULT=$(create_feature_environment "feature" "$FEATURE_DESCRIPTION" "$SPECS_DIR" "$REPO_ROOT/templates/spec-template.md" "spec.md")

# Extract results
eval "$RESULT"

# Get additional info
FEATURE_NUM=$(echo "$DIR_NAME" | grep -o '^[0-9]\+')

log_success "Successfully created feature environment for '$FEATURE_DESCRIPTION'."

# --- Output Results ---
if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s","FEATURE_DIR":"%s"}\n' \
           "$BRANCH_NAME" "$FEATURE_DIR/spec.md" "$FEATURE_NUM" "$FEATURE_DIR"
else
    echo "Feature environment created:"
    echo "  BRANCH_NAME: $BRANCH_NAME"
    echo "  SPEC_FILE: $FEATURE_DIR/spec.md"
    echo "  FEATURE_NUM: $FEATURE_NUM"
    echo "  FEATURE_DIR: $FEATURE_DIR"
fi
