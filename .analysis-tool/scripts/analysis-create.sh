#!/usr/bin/env bash
#
# Create architecture analysis from source files (Views, Controllers, Components, etc.)
# This script validates environment and detects technology stack automatically.
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
eval $(get_analysis_paths)

# --- Technology Stack Detection ---
detect_tech_stack() {
    local files=("$@")
    local has_cshtml=false
    local has_cs_controller=false
    local has_tsx=false
    local has_ts_api=false
    local has_vue=false
    
    for file in "${files[@]}"; do
        case "${file##*.}" in
            cshtml) has_cshtml=true ;;
            cs) 
                if [[ $file == *Controller.cs ]]; then
                    has_cs_controller=true
                fi
                ;;
            tsx|jsx) has_tsx=true ;;
            ts|js) 
                if [[ $file == */api/* || $file == */routes/* ]]; then
                    has_ts_api=true
                fi
                ;;
            vue) has_vue=true ;;
        esac
    done
    
    # Determine technology stack
    if [[ $has_cshtml == true || $has_cs_controller == true ]]; then
        echo "dotnet-mvc"
    elif [[ $has_tsx == true ]]; then
        echo "react"
    elif [[ $has_vue == true ]]; then
        echo "vue"
    elif [[ $has_ts_api == true ]]; then
        echo "nodejs"
    else
        echo "generic"
    fi
}

# --- File Role Detection ---
get_file_role() {
    local file=$1
    local ext="${file##*.}"
    
    case $ext in
        cshtml) echo "view" ;;
        cs) 
            if [[ $file == *Controller.cs ]]; then
                echo "controller"
            elif [[ $file == */BL/* || $file == */BLV2/* || $file == */Services/* || $file == *Service.cs ]]; then
                echo "service"
            else
                echo "utility"
            fi
            ;;
        tsx|jsx)
            if [[ $file == */pages/* ]]; then
                echo "page-component"
            elif [[ $file == */components/* ]]; then
                echo "component"
            elif [[ $file == */api/* ]]; then
                echo "api-route"
            else
                echo "component"
            fi
            ;;
        ts|js)
            if [[ $file == */api/* || $file == */routes/* ]]; then
                echo "api-route"
            elif [[ $file == */services/* || $file == *Service.ts || $file == *Service.js ]]; then
                echo "service"
            else
                echo "utility"
            fi
            ;;
        vue) echo "component" ;;
        *) echo "unknown" ;;
    esac
}

show_help() {
    echo "Usage: $0 <type> <file1> [<file2>...]"
    echo "       $0 --create-components"
    echo ""
    echo "Description:"
    echo "  Analyzes source files and creates structured documentation."
    echo "  Supports: .cshtml/.cs (ASP.NET), .tsx/.ts (React/Node), .vue (Vue)"
    echo ""
    echo "Arguments:"
    echo "  <type>             Type of analysis. Must be one of: arch, view, server, service"
    echo "  <file>             Path to source file(s) to analyze"
    echo ""
    echo "Options:"
    echo "  --create-components  Create component/action markdown files from README.md (internal use)"
    echo ""
    echo "Examples:"
    echo "  # Create overall architecture analysis"
    echo "  $0 arch Views/Home/Index.cshtml Controllers/HomeController.cs"
    echo ""
    echo "  # Analyze view files to identify components"
    echo "  $0 view Views/Home/Index.cshtml"
    echo ""
    echo "  # Create components after README.md is updated"
    echo "  $0 --create-components"
}

# --- Main ---

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--create-components" ]]; then
    CREATE_COMPONENTS=true
else
    CREATE_COMPONENTS=false
    TYPE="$1"
    shift
    SOURCE_FILES=("$@")

    if [[ -z "$TYPE" ]]; then
        log_error "Error: Type parameter is missing." >&2
        show_help >&2
        exit 1
    fi

    case "$TYPE" in
        arch|view|server|service)
            ;; # valid type
        *)
            log_error "Error: Invalid type '$TYPE'." >&2
            log_error "Allowed types are: arch, view, server, service." >&2
            exit 1
            ;;
    esac
fi

# --- If --create-components flag is set, create files from README.md or architecture.md ---
if $CREATE_COMPONENTS; then
    # Check if README.md exists (new architecture)
    README_FILE="$PAGE_ANALYSIS_DIR/README.md"
    ARCH_FILE="$PAGE_ANALYSIS_DIR/architecture.md"
    OVERVIEW_FILE="$PAGE_ANALYSIS_DIR/overview.md"
    
    SOURCE_FILE=""
    if [[ -f "$README_FILE" ]]; then
        SOURCE_FILE="$README_FILE"
        log_info "Using README.md as source for component list"
    elif [[ -f "$ARCH_FILE" ]]; then
        SOURCE_FILE="$ARCH_FILE"
        log_info "Using architecture.md as source for component list (legacy)"
    elif [[ -f "$OVERVIEW_FILE" ]]; then
        SOURCE_FILE="$OVERVIEW_FILE"
        log_info "Using overview.md as source for component list (legacy)"
    else
        log_error "README.md, architecture.md, or overview.md not found at: $PAGE_ANALYSIS_DIR"
        log_error "AI must create analysis files first."
        exit 1
    fi

    # Check if templates exist
    VIEW_TEMPLATE_FILE="$KIT_DIR/templates/view-template.md"
    SERVER_TEMPLATE_FILE="$KIT_DIR/templates/server-template.md"
    SERVICE_TEMPLATE_FILE="$KIT_DIR/templates/service-template.md"
    
    # Validate all required templates
    for template_file in "$VIEW_TEMPLATE_FILE" "$SERVER_TEMPLATE_FILE" "$SERVICE_TEMPLATE_FILE"; do
        if [[ ! -f "$template_file" ]]; then
            log_error "Template not found at: $template_file"
            exit 1
        fi
    done

    log_info "Creating component/action files from $(basename $SOURCE_FILE)..."

    # Extract links from markdown tables and inline links
    # Pattern 1: Table format - | [view-01-name.md](./view-01-name.md) |
    # Pattern 2: Inline format - [view-01-name.md]
    VIEW_LINKS=$(grep -o '\[view-[0-9]\+-[^]]*\.md\]' "$SOURCE_FILE" | sed 's/^\[\(.*\)\]$/\1/' || true)
    COMPONENT_LINKS=$(grep -o '\[component-[0-9]\+-[^]]*\.md\]' "$SOURCE_FILE" | sed 's/^\[\(.*\)\]$/\1/' || true)
    PAGE_LINKS=$(grep -o '\[page-[0-9]\+-[^]]*\.md\]' "$SOURCE_FILE" | sed 's/^\[\(.*\)\]$/\1/' || true)
    
    # Extract server/service-* links (service-get, service-post, service-put, service-delete, etc.)
    SERVER_LINKS=$(grep -o '\[server-[0-9]\+-[^]]*\.md\]' "$SOURCE_FILE" | sed 's/^\[\(.*\)\]$/\1/' || true)
    SERVICE_METHOD_LINKS=$(grep -o '\[service-\(get\|post\|put\|delete\|patch\)-[0-9]\+-[^]]*\.md\]' "$SOURCE_FILE" | sed 's/^\[\(.*\)\]$/\1/' || true)

    # Combine all links and remove duplicates
    ALL_LINKS=$(echo -e "$VIEW_LINKS\n$COMPONENT_LINKS\n$PAGE_LINKS\n$SERVER_LINKS\n$SERVICE_METHOD_LINKS" | grep -v '^$' | sort -u)

    if [[ -z "$ALL_LINKS" ]]; then
        log_warning "No component/action links found in $(basename $SOURCE_FILE)."
        log_info "Expected format: [view-01-name.md](./view-01-name.md)"
        exit 0
    fi
    
    log_info "Found $(echo "$ALL_LINKS" | wc -l | tr -d ' ') component/action files to create"

    # Create each file
    CREATED_COUNT=0
    while IFS= read -r filename; do
        if [[ -n "$filename" ]]; then
            FILE_PATH="$PAGE_ANALYSIS_DIR/$filename"
            if [[ ! -f "$FILE_PATH" ]]; then
                # Determine file type and use appropriate template
                if [[ $filename == view-* || $filename == component-* || $filename == page-* ]]; then
                    TEMPLATE_FILE="$VIEW_TEMPLATE_FILE"
                    NAME=$(echo "$filename" | sed 's/^[a-z]\+-[0-9]\+-\(.*\)\.md$/\1/')
                    NUMBER=$(echo "$filename" | sed 's/^[a-z]\+-\([0-9]\+\)-.*\.md$/\1/')
                elif [[ $filename == server-* ]]; then
                    TEMPLATE_FILE="$SERVER_TEMPLATE_FILE"
                    NAME=$(echo "$filename" | sed 's/^server-[0-9]\+-\(.*\)\.md$/\1/')
                    NUMBER=$(echo "$filename" | sed 's/^server-\([0-9]\+\)-.*\.md$/\1/')
                elif [[ $filename =~ ^service-(get|post|put|delete|patch)- ]]; then
                    TEMPLATE_FILE="$SERVICE_TEMPLATE_FILE"
                    NAME=$(echo "$filename" | sed 's/^service-[a-z]\+-[0-9]\+-\(.*\)\.md$/\1/')
                    NUMBER=$(echo "$filename" | sed 's/^service-[a-z]\+-\([0-9]\+\)-.*\.md$/\1/')
                else
                    continue
                fi
                
                # Create file from template
                sed "s/\[功能區塊編號\]/\[${NUMBER}\]/; s/\[功能區塊名稱\]/${NAME}/; s/\[服務方法名稱\]/${NAME}/" "$TEMPLATE_FILE" > "$FILE_PATH"
                log_success "Created: $filename"
                CREATED_COUNT=$((CREATED_COUNT + 1))
            else
                log_info "Already exists: $filename"
            fi
        fi
    done <<< "$ALL_LINKS"

    if [[ $CREATED_COUNT -gt 0 ]]; then
        log_success "Created $CREATED_COUNT component/action files."
    else
        log_info "All component/action files already exist."
    fi

    exit 0
fi

# --- Default mode: Validate environment for architecture analysis ---
if [[ "$CREATE_COMPONENTS" == false && ${#SOURCE_FILES[@]} -eq 0 ]]; then
    log_error "Error: At least one source file is required for analysis." >&2
    show_help >&2
    exit 1
fi

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1
if [[ ! -d "$PAGE_ANALYSIS_DIR" ]]; then
    log_error "Analysis directory not found: $PAGE_ANALYSIS_DIR" >&2
    log_error "Run /analysis-init first." >&2
    exit 1
fi

# --- Detect Incremental Mode ---
ARCH_FILE="$PAGE_ANALYSIS_DIR/architecture.md"
OVERVIEW_FILE="$PAGE_ANALYSIS_DIR/overview.md"
INCREMENTAL_MODE=false

if [[ -f "$ARCH_FILE" ]] || [[ -f "$OVERVIEW_FILE" ]]; then
    INCREMENTAL_MODE=true
    log_info "📂 Incremental mode: architecture analysis exists"
    if [[ -f "$ARCH_FILE" ]]; then
        log_info "   Existing file: $ARCH_FILE"
    else
        log_info "   Existing file: $OVERVIEW_FILE (legacy format)"
    fi
    log_info "   → Will analyze new files and merge components/actions"
    log_info ""
else
    log_info "📝 Initial mode: Creating new architecture analysis"
    log_info ""
fi

# --- Validate Source Files ---
for source_file in "${SOURCE_FILES[@]}"; do
    if [[ ! -f "$source_file" ]]; then
        log_error "Source file not found: $source_file" >&2
        exit 1
    fi
done

# --- Detect Technology Stack ---
TECH_STACK=$(detect_tech_stack "${SOURCE_FILES[@]}")

# --- Categorize Files by Role ---
VIEW_FILES=()
CONTROLLER_FILES=()
COMPONENT_FILES=()
API_FILES=()
SERVICE_FILES=()

for source_file in "${SOURCE_FILES[@]}"; do
    ROLE=$(get_file_role "$source_file")
    case $ROLE in
        view) VIEW_FILES+=("$source_file") ;;
        controller) CONTROLLER_FILES+=("$source_file") ;;
        component|page-component) COMPONENT_FILES+=("$source_file") ;;
        api-route) API_FILES+=("$source_file") ;;
        service) SERVICE_FILES+=("$source_file") ;;
    esac
done

# --- Environment Validation Passed ---
log_success "Environment validation passed"
log_info "Analysis directory: $PAGE_ANALYSIS_DIR"
log_info "Analysis type:      $TYPE"
log_info "Technology stack: $TECH_STACK"
log_info ""
log_info "Source files categorized:"
[[ ${#VIEW_FILES[@]} -gt 0 ]] && log_info "  Views: ${VIEW_FILES[*]}"
[[ ${#CONTROLLER_FILES[@]} -gt 0 ]] && log_info "  Controllers: ${CONTROLLER_FILES[*]}"
[[ ${#COMPONENT_FILES[@]} -gt 0 ]] && log_info "  Components: ${COMPONENT_FILES[*]}"
[[ ${#API_FILES[@]} -gt 0 ]] && log_info "  API Routes: ${API_FILES[*]}"
[[ ${#SERVICE_FILES[@]} -gt 0 ]] && log_info "  Services: ${SERVICE_FILES[*]}"
log_info ""
log_info "AI will now analyze the source files and create the architecture analysis."

