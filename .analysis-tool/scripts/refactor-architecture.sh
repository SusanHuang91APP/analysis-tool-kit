#!/usr/bin/env bash
#
# Generate refactor-architecture.md from architecture.md and server-*.md files
# This script validates environment and detects source files.
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
            echo "  Generate refactor-architecture.md from analysis files"
            echo ""
            echo "Arguments:"
            echo "  [file]   Optional: specific server-*.md or service-*.md files to analyze"
            echo "           If not provided, all server-*.md files will be used"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 server-01-xxx.md server-02-xxx.md"
            echo "  $0 service-get-01-xxx.md"
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

# --- Check if architecture.md exists ---
ARCH_FILE="$PAGE_ANALYSIS_DIR/architecture.md"
if [[ ! -f "$ARCH_FILE" ]]; then
    log_error "architecture.md not found at: $ARCH_FILE"
    log_error "Run /analysis-create first to create architecture analysis."
    exit 1
fi

# --- Determine which server files to use ---
if [[ ${#SPECIFIED_FILES[@]} -gt 0 ]]; then
    # Use specified files
    SERVER_FILES=()
    for file in "${SPECIFIED_FILES[@]}"; do
        # Check if file is relative or absolute
        if [[ "$file" = /* ]]; then
            # Absolute path
            if [[ -f "$file" ]]; then
                SERVER_FILES+=("$file")
            else
                log_error "Specified file not found: $file"
                exit 1
            fi
        else
            # Relative path, prepend PAGE_ANALYSIS_DIR
            full_path="$PAGE_ANALYSIS_DIR/$file"
            if [[ -f "$full_path" ]]; then
                SERVER_FILES+=("$full_path")
            else
                log_error "Specified file not found: $full_path"
                exit 1
            fi
        fi
    done
    log_info "Using specified files: ${#SERVER_FILES[@]}"
else
    # Find all server-*.md files
    SERVER_FILES=($(find "$PAGE_ANALYSIS_DIR" -name "server-*.md" -o -name "service-*.md" -type f | sort))
    
    if [[ ${#SERVER_FILES[@]} -eq 0 ]]; then
        log_warning "No server-*.md or service-*.md files found in: $PAGE_ANALYSIS_DIR"
        log_info "Will generate refactor-architecture.md based on architecture.md only."
    fi
fi

# --- Output file path ---
OUTPUT_FILE="$PAGE_ANALYSIS_DIR/refactor-architecture.md"

# --- Check if output file exists ---
OUTPUT_MODE="create"
if [[ -f "$OUTPUT_FILE" ]]; then
    OUTPUT_MODE="update"
    log_info "Output file exists: will UPDATE existing file"
else
    log_info "Output file not found: will CREATE new file"
fi

# --- Validation passed ---
log_success "Environment validation passed"
log_info "Analysis directory: $PAGE_ANALYSIS_DIR"
log_info "Architecture file: $ARCH_FILE"
log_info "Server files found: ${#SERVER_FILES[@]}"
log_info "Output file: $OUTPUT_FILE"
log_info "Output mode: $OUTPUT_MODE"
log_info ""

# Output paths for AI to use
echo "ARCH_FILE='$ARCH_FILE'"
echo "OUTPUT_FILE='$OUTPUT_FILE'"
echo "OUTPUT_MODE='$OUTPUT_MODE'"
echo "SERVER_FILES_COUNT=${#SERVER_FILES[@]}"

# List server files
if [[ ${#SERVER_FILES[@]} -gt 0 ]]; then
    echo "SERVER_FILES=("
    for file in "${SERVER_FILES[@]}"; do
        echo "  '$file'"
    done
    echo ")"
fi

log_info ""
if [[ "$OUTPUT_MODE" == "update" ]]; then
    log_info "AI will now UPDATE refactor-architecture.md based on:"
else
    log_info "AI will now CREATE refactor-architecture.md based on:"
fi
log_info "  - architecture.md (架構分析)"
log_info "  - server-*.md files (後端端點)"
log_info "  - architecture-refactor-template.md (範本)"
log_info "  - refactor-constitution.md (重構憲法)"
