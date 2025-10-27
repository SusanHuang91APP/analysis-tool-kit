#!/usr/bin/env bash
#
# Create analysis files for V2 architecture
# Supports both Topic and Shared analysis file creation
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

# --- Infer filename from source files ---
infer_filename_from_sources() {
    local files=("$@")
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "unnamed"
        return
    fi
    
    # Use first file's basename without extension
    local first_file="${files[0]}"
    local basename=$(basename "$first_file")
    local name="${basename%.*}"
    
    # Remove common suffixes
    name=$(echo "$name" | sed 's/Controller$//' | sed 's/Service$//' | sed 's/Component$//')
    
    # Convert to lowercase and replace spaces/underscores with hyphens
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    
    echo "$name"
}

show_help() {
    echo "Usage: $0 <type> [source-files...]"
    echo ""
    echo "Description:"
    echo "  Creates analysis files based on type and registers them in overview.md"
    echo ""
    echo "Arguments:"
    echo "  <type>             Type of analysis. Topic types: server, client, feature, api"
    echo "                     Shared types: request-pipeline, component, helper"
    echo "  [source-files...]  Optional: Source files to analyze"
    echo ""
    echo "Examples:"
    echo "  # Create feature analysis (Topic)"
    echo "  $0 feature Controllers/MemberController.cs"
    echo ""
    echo "  # Create API analysis (Topic)"
    echo "  $0 api Routes/api/members.ts"
    echo ""
    echo "  # Create shared component analysis"
    echo "  $0 component Components/LoginForm.tsx"
    echo ""
    echo "  # Create request pipeline analysis"
    echo "  $0 request-pipeline Filters/AuthFilter.cs"
}

# --- Argument Parsing ---
TYPE=""
NAME=""
SOURCE_FILES=()
JSON_MODE=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --type)
            TYPE="$2"
            shift; shift
            ;;
        --name)
            NAME="$2"
            shift; shift
            ;;
        --json)
            JSON_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            SOURCE_FILES+=("$1")
            shift
            ;;
    esac
done


# --- Main ---

if [[ -z "$TYPE" ]]; then
    log_error "Error: --type parameter is missing." >&2
    show_help >&2
    exit 1
fi

# Validate type
VALID_TYPES=("server" "client" "feature" "api" "request-pipeline" "helper" "component")
if [[ ! " ${VALID_TYPES[@]} " =~ " ${TYPE} " ]]; then
    log_error "Error: Invalid type '$TYPE'." >&2
    log_error "Valid types: ${VALID_TYPES[*]}" >&2
    exit 1
fi

# --- Prerequisites Check ---
check_analysis_branch "$CURRENT_BRANCH" || exit 1

# --- Determine Category and Target Directory ---
TARGET_DIR=$(get_target_directory "$TOPIC_DIR" "$TYPE")

if [[ -z "$TARGET_DIR" ]]; then
    log_error "Could not determine target directory for type: $TYPE" >&2
    exit 1
fi

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# --- Determine Template ---
TEMPLATE_FILE="$TEMPLATES_DIR/${TYPE}-template.md"
if [[ "$TYPE" == "component" ]]; then
    TEMPLATE_FILE="$TEMPLATES_DIR/feature-template.md"
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template not found: $TEMPLATE_FILE" >&2
    exit 1
fi

# --- Infer Filename ---
if [[ -n "$NAME" ]]; then
    if [[ "$TYPE" == "api" || "$TYPE" == "helper" || "$TYPE" == "request-pipeline" || "$TYPE" == "component" ]]; then
        # Use PascalCase name directly
        INFERRED_NAME="$NAME"
    else
        # For other types (like feature with Chinese name), convert spaces to hyphens and ensure lowercase for any accidental English characters.
        INFERRED_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    fi
elif [[ ${#SOURCE_FILES[@]} -gt 0 ]]; then
    INFERRED_NAME=$(infer_filename_from_sources "${SOURCE_FILES[@]}")
else
    INFERRED_NAME="unnamed"
fi

# --- Calculate File Number ---
if [[ "$TYPE" == "server" || "$TYPE" == "client" ]]; then
    # These files don't have numbers, they're at topic root
    FILE_NAME="${TYPE}.md"
    FILE_PATH="$TOPIC_DIR/$FILE_NAME"
    
    # Check if file already exists
    if [[ -f "$FILE_PATH" ]]; then
        log_warning "File already exists: $FILE_PATH"
        log_info "Use /analysis.analyze to update existing file."
        exit 0
    fi
else
    # Feature, api, shared types - use numbered format ###-name.md
    FILE_NUM=$(get_next_file_number "$TARGET_DIR")
    FORMATTED_NUM=$(format_number "$FILE_NUM")
    FILE_NAME="${FORMATTED_NUM}-${INFERRED_NAME}.md"
    FILE_PATH="$TARGET_DIR/$FILE_NAME"
fi

# --- Create File from Template ---
log_info "Creating $TYPE analysis: $FILE_NAME"
cp "$TEMPLATE_FILE" "$FILE_PATH"

# Update template placeholders
CURRENT_DATE=$(date +%Y-%m-%d)
sed -i.bak \
    -e "s/__NAME__/$INFERRED_NAME/g" \
    -e "s/__CURRENT_DATE__/$CURRENT_DATE/g" \
    "$FILE_PATH"
rm -f "${FILE_PATH}.bak"

log_success "Created: $FILE_PATH"

# --- Register in overview.md ---
OVERVIEW_FILE="$TOPIC_DIR/overview.md"

if [[ "$TYPE" == "server" || "$TYPE" == "client" ]]; then
    RELATIVE_PATH="./${FILE_NAME}"
elif [[ "$TYPE" == "feature" ]]; then
    RELATIVE_PATH="./features/${FILE_NAME}"
elif [[ "$TYPE" == "api" ]]; then
    RELATIVE_PATH="./apis/${FILE_NAME}"
elif [[ "$TYPE" == "helper" ]]; then
    RELATIVE_PATH="./helpers/${FILE_NAME}"
elif [[ "$TYPE" == "request-pipeline" ]]; then
    RELATIVE_PATH="./request-pipeline/${FILE_NAME}"
elif [[ "$TYPE" == "component" ]]; then
    RELATIVE_PATH="./components/${FILE_NAME}"
fi

# Update overview.md
if [[ -f "$OVERVIEW_FILE" ]]; then
    update_overview_manifest "$OVERVIEW_FILE" "$FILE_NAME" "$RELATIVE_PATH" "📝 待分析"
else
    log_warning "Overview file not found: $OVERVIEW_FILE"
fi

# --- Validate Source Files ---
if [[ ${#SOURCE_FILES[@]} -gt 0 ]]; then
    for source_file in "${SOURCE_FILES[@]}"; do
        if [[ ! -f "$source_file" ]]; then
            log_warning "Source file not found: $source_file"
        fi
    done
    
    # Detect Technology Stack
    TECH_STACK=$(detect_tech_stack "${SOURCE_FILES[@]}")
    
    # Categorize Files by Role
    VIEW_FILES=()
    CONTROLLER_FILES=()
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
    
    log_info ""
    log_info "Source files provided:"
    log_info "  Technology stack: $TECH_STACK"
    [[ ${#VIEW_FILES[@]} -gt 0 ]] && log_info "  Views: ${VIEW_FILES[*]}"
    [[ ${#CONTROLLER_FILES[@]} -gt 0 ]] && log_info "  Controllers: ${CONTROLLER_FILES[*]}"
    [[ ${#COMPONENT_FILES[@]} -gt 0 ]] && log_info "  Components: ${COMPONENT_FILES[*]}"
    [[ ${#API_FILES[@]} -gt 0 ]] && log_info "  API Routes: ${API_FILES[*]}"
    [[ ${#SERVICE_FILES[@]} -gt 0 ]] && log_info "  Services: ${SERVICE_FILES[*]}"
    log_info ""
    log_info "AI should fill metadata table with source files list."
fi

# --- Output Results ---
log_info ""
log_success "Analysis file created successfully!"
log_info "File: $FILE_PATH"
log_info "Registered in: $OVERVIEW_FILE"
log_info "Quality level: 📝 待分析"
log_info ""
log_info "Next step: Use /analysis.analyze $FILE_NAME [source-files...] to improve quality."

if $JSON_MODE; then
    printf '{"FILE_PATH":"%s","FILE_NAME":"%s","OVERVIEW_FILE":"%s"}\n' \
           "$FILE_PATH" "$FILE_NAME" "$OVERVIEW_FILE"
fi

