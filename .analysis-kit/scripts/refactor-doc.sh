#!/usr/bin/env bash
#
# Create refactor specification documents from legacy analysis files
# Usage: ./refactor-doc.sh [<target-file>] <analysis-files...>
#
# Supports two formats:
#   Format 1: ./refactor-doc.sh <analysis-files...>
#     - Auto-generates target file in refactors/ directory
#   Format 2: ./refactor-doc.sh <target-file> <analysis-files...>
#     - Uses specified target file path
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

show_help() {
    echo "Usage: $0 [<target-file>] <analysis-files...>"
    echo ""
    echo "Description:"
    echo "  Creates a refactor specification document from legacy analysis files."
    echo "  Supports two formats:"
    echo ""
    echo "  Format 1 (Auto-generate):"
    echo "    $0 <analysis-files...>"
    echo "    - Auto-generates target file in refactors/ directory"
    echo "    - Example: $0 analysis/001-topic/features/002-MediaGallery.md"
    echo ""
    echo "  Format 2 (Specify target):"
    echo "    $0 <target-file> <analysis-files...>"
    echo "    - Uses specified target file path"
    echo "    - Example: $0 refactors/001-media-gallery.md analysis/001-topic/features/002-MediaGallery.md"
    echo ""
    echo "Arguments:"
    echo "  <target-file> (optional)  Target refactor document path (Format 2)"
    echo "  <analysis-files...>       One or more analysis markdown files to refactor"
    echo ""
    echo "Output:"
    echo "  Creates refactors/###-<name>.md and outputs environment variables for AI"
}

# --- Extract name from analysis filename ---
extract_feature_name() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # Remove .md extension
    local name="${filename%.md}"
    
    # Remove number prefix (e.g., "002-MediaGallery" -> "MediaGallery")
    name=$(echo "$name" | sed 's/^[0-9]*-//')
    
    echo "$name"
}

# --- Convert name to kebab-case ---
to_kebab_case() {
    local name="$1"
    
    # Convert PascalCase/camelCase to kebab-case
    # Insert hyphen before uppercase letters, then lowercase everything
    echo "$name" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1-\2/g' | tr '[:upper:]' '[:lower:]'
}

# --- Detect format and parse arguments ---
detect_format() {
    local first_arg="$1"
    
    # Check if first argument is a markdown file path (Format 2)
    # Pattern: ends with .md and exists in refactors/ directory or is absolute path
    if [[ "$first_arg" =~ \.md$ ]]; then
        # If it's an analysis file (starts with analysis/), it's Format 1
        if [[ "$first_arg" =~ ^analysis/ ]]; then
            echo "format1"
            return 0
        fi
        # Check if it's an absolute path
        if [[ "$first_arg" =~ ^/ ]]; then
            echo "format2"
            return 0
        fi
        # Check if it's relative path in refactors/ directory
        if [[ "$first_arg" =~ ^refactors/ ]]; then
            echo "format2"
            return 0
        fi
        # Check if file exists and is in refactors/ directory (for existing files)
        if [[ -f "$first_arg" ]] && [[ "$first_arg" =~ refactors/ ]]; then
            echo "format2"
            return 0
        fi
    fi
    
    echo "format1"
    return 0
}

# --- Main ---

# Check for help flag
if [[ "$1" == "--help" || "$1" == "-h" || $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Get paths first (needed for format detection)
eval $(get_analysis_paths)

# Detect format based on first argument
FORMAT=$(detect_format "$1")

if [[ "$FORMAT" == "format2" ]]; then
    # Format 2: <target-file> <analysis-files...>
    TARGET_FILE="$1"
    shift
    ANALYSIS_FILES=("$@")
    
    if [[ ${#ANALYSIS_FILES[@]} -eq 0 ]]; then
        log_error "Format 2 requires at least one analysis file after target file." >&2
        show_help >&2
        exit 1
    fi
    
    # Normalize target file path
    if [[ "$TARGET_FILE" =~ ^refactors/ ]]; then
        # Relative path: make it absolute
        TARGET_FILE="$KIT_PARENT_DIR/$TARGET_FILE"
    elif [[ ! "$TARGET_FILE" =~ ^/ ]]; then
        # Relative path from current directory: make it absolute
        TARGET_FILE="$(cd "$(dirname "$TARGET_FILE")" && pwd)/$(basename "$TARGET_FILE")"
    fi
    
    log_info "Format 2 detected: Using specified target file: $TARGET_FILE"
else
    # Format 1: <analysis-files...>
    ANALYSIS_FILES=("$@")
    TARGET_FILE=""
    
    if [[ ${#ANALYSIS_FILES[@]} -eq 0 ]]; then
        log_error "No analysis files provided." >&2
        show_help >&2
        exit 1
    fi
    
    log_info "Format 1 detected: Auto-generating target file"
fi

log_info "Processing ${#ANALYSIS_FILES[@]} analysis file(s)..."

# --- Validate all input files exist ---
INVALID_FILES=()
for file in "${ANALYSIS_FILES[@]}"; do
    # Resolve file path (handle relative paths)
    resolved_file="$file"
    if [[ ! "$file" =~ ^/ ]] && [[ ! -f "$file" ]]; then
        # Try relative to current directory
        resolved_file="$(pwd)/$file"
    fi
    
    if [[ ! -f "$resolved_file" ]] && [[ ! -f "$file" ]]; then
        INVALID_FILES+=("$file")
        log_error "File not found: $file" >&2
    elif [[ ! "$file" =~ \.md$ ]]; then
        INVALID_FILES+=("$file")
        log_error "Not a markdown file: $file" >&2
    fi
done

if [[ ${#INVALID_FILES[@]} -gt 0 ]]; then
    log_error "Found ${#INVALID_FILES[@]} invalid file(s). Aborting." >&2
    exit 1
fi

log_success "All input files validated."

# --- Determine output file path ---
if [[ -n "$TARGET_FILE" ]]; then
    # Format 2: Use specified target file
    OUTPUT_FILE="$TARGET_FILE"
    
    # Create directory if it doesn't exist
    OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
    mkdir -p "$OUTPUT_DIR"
    
    log_info "Using specified target file: $OUTPUT_FILE"
    
    # Extract name from target file for template placeholder replacement
    TARGET_BASENAME=$(basename "$OUTPUT_FILE" .md)
    # Remove number prefix if exists (e.g., "001-media-gallery" -> "media-gallery")
    EXTRACTED_NAME=$(echo "$TARGET_BASENAME" | sed 's/^[0-9]*-//')
else
    # Format 1: Auto-generate target file
    REFACTORS_DIR="$KIT_PARENT_DIR/refactors"
    mkdir -p "$REFACTORS_DIR"
    
    # Calculate next file number
    NEXT_NUM=$(get_next_file_number "$REFACTORS_DIR")
    FORMATTED_NUM=$(format_number "$NEXT_NUM" 3)
    
    log_info "Next document number: $FORMATTED_NUM"
    
    # Extract and format name from first analysis file
    FIRST_FILE="${ANALYSIS_FILES[0]}"
    EXTRACTED_NAME=$(extract_feature_name "$FIRST_FILE")
    KEBAB_NAME=$(to_kebab_case "$EXTRACTED_NAME")
    
    # Use kebab-case name directly (no suffix)
    FINAL_NAME="${KEBAB_NAME}"
    
    log_info "Extracted name: $EXTRACTED_NAME"
    log_info "Formatted name: $FINAL_NAME"
    
    # Create output filename
    OUTPUT_FILENAME="${FORMATTED_NUM}-${FINAL_NAME}.md"
    OUTPUT_FILE="$REFACTORS_DIR/$OUTPUT_FILENAME"
    
    log_info "Output file: $OUTPUT_FILE"
fi

# --- Check if template exists ---
TEMPLATE_FILE="$TEMPLATES_DIR/refactor-template.md"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template file not found: $TEMPLATE_FILE" >&2
    log_error "Please ensure the template file exists at: $TEMPLATE_FILE" >&2
    exit 1
fi

# --- Handle existing target file (Format 2) ---
if [[ -n "$TARGET_FILE" ]] && [[ -f "$OUTPUT_FILE" ]]; then
    log_info "Target file already exists: $OUTPUT_FILE"
    log_info "AI will update the existing file instead of creating a new one."
    # Don't overwrite existing file, just use it
    EXISTING_FILE=true
else
    # Copy template to output location
    log_info "Copying template to: $OUTPUT_FILE"
    cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
    EXISTING_FILE=false
    
    # --- Update template placeholders ---
    CURRENT_DATE=$(date +%Y-%m-%d)
    
    # Replace placeholders in the file
    # Note: The template has escaped brackets \[ and \]
    # Use different sed command based on OS (macOS vs Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i.bak \
            -e "s/\\\\\\[填入頁面\\/模組\\/功能名稱\\\\\\]/$EXTRACTED_NAME/g" \
            -e "s/__CURRENT_DATE__/$CURRENT_DATE/g" \
            "$OUTPUT_FILE"
        rm -f "${OUTPUT_FILE}.bak"
    else
        # Linux
        sed -i \
            -e "s/\\\\\\[填入頁面\\/模組\\/功能名稱\\\\\\]/$EXTRACTED_NAME/g" \
            -e "s/__CURRENT_DATE__/$CURRENT_DATE/g" \
            "$OUTPUT_FILE"
    fi
    
    log_success "Created refactor document: $OUTPUT_FILE"
fi

# --- Check for refactor constitution ---
REFACTOR_CONSTITUTION="$KIT_DIR/memory/refactor-constitution.md"
if [[ ! -f "$REFACTOR_CONSTITUTION" ]]; then
    log_warning "Refactor constitution not found: $REFACTOR_CONSTITUTION"
    log_warning "Using standard constitution instead."
    REFACTOR_CONSTITUTION="$CONSTITUTION_FILE"
fi

# --- Output environment variables for AI ---
echo ""
echo "=== Environment Variables for AI ==="
echo "REFACTOR_DOC_FILE='$OUTPUT_FILE'"
echo "LEGACY_ANALYSIS_FILES='${ANALYSIS_FILES[*]}'"
echo "CONSTITUTION_FILE='$REFACTOR_CONSTITUTION'"
if [[ "$EXISTING_FILE" == "true" ]]; then
    echo "EXISTING_FILE='true'"
else
    echo "EXISTING_FILE='false'"
fi
echo ""
log_info "AI should now:"
log_info "  1. Read the constitution file to understand refactoring principles"
log_info "  2. Read all legacy analysis files"
if [[ "$EXISTING_FILE" == "true" ]]; then
    log_info "  3. Read the existing refactor document and update it"
else
    log_info "  3. Fill in the refactor template sections based on the analysis"
fi
log_info "  4. Write the complete refactor specification to the output file"
log_info "  5. Perform functionality consistency check"
echo ""
log_success "Script completed. Handing over to AI."

