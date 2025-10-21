#!/usr/bin/env bash
#
# Prints all important paths for the current analysis environment (V2)
# Useful for debugging and verifying environment configuration
#
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

eval $(get_analysis_paths)

# Check if on analysis branch
if ! check_analysis_branch "$CURRENT_BRANCH"; then
    echo ""
    echo "⚠️  Not on an analysis branch. Some paths may not be available."
    echo ""
fi

echo "=== Analysis Tool Kit V2 - Environment Paths ==="
echo ""
echo "Git & Repository:"
echo "  REPO_ROOT:           $REPO_ROOT"
echo "  CURRENT_BRANCH:      $CURRENT_BRANCH"
echo ""
echo "Tool Kit:"
echo "  KIT_DIR:             $KIT_DIR"
echo "  KIT_PARENT_DIR:      $KIT_PARENT_DIR"
echo "  CONSTITUTION_FILE:   $CONSTITUTION_FILE"
echo "  TEMPLATES_DIR:       $TEMPLATES_DIR"
echo ""
echo "Analysis Structure:"
echo "  ANALYSIS_BASE_DIR:   $ANALYSIS_BASE_DIR"
echo "  SHARED_DIR:          $SHARED_DIR"
echo "  TOPIC_DIR:           $TOPIC_DIR"
echo ""
echo "Key Files:"
if [[ -d "$TOPIC_DIR" ]]; then
    echo "  Topic Overview:      $TOPIC_DIR/overview.md"
    [[ -f "$TOPIC_DIR/server.md" ]] && echo "  Topic Server:        $TOPIC_DIR/server.md"
    [[ -f "$TOPIC_DIR/client.md" ]] && echo "  Topic Client:        $TOPIC_DIR/client.md"
fi
if [[ -d "$SHARED_DIR" ]]; then
    echo "  Shared Overview:     $SHARED_DIR/overview.md"
fi
echo ""
echo "Directory Structure Status:"

# Check if analysis base directory exists
if [[ -d "$ANALYSIS_BASE_DIR" ]]; then
    echo "  ✓ Analysis base directory exists"
    
    # Count topics
    TOPIC_COUNT=$(find "$ANALYSIS_BASE_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | wc -l | tr -d ' ')
    echo "  ✓ Topics found: $TOPIC_COUNT"
    
    # List topics
    if [[ $TOPIC_COUNT -gt 0 ]]; then
        echo ""
        echo "  Topics:"
        find "$ANALYSIS_BASE_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | sort | while read -r topic; do
            echo "    - $(basename "$topic")"
        done
    fi
else
    echo "  ✗ Analysis base directory does not exist"
fi

# Check shared structure
echo ""
if [[ -d "$SHARED_DIR" ]]; then
    echo "  ✓ Shared directory exists"
    [[ -d "$SHARED_DIR/request-pipeline" ]] && echo "    ✓ request-pipeline/"
    [[ -d "$SHARED_DIR/components" ]] && echo "    ✓ components/"
    [[ -d "$SHARED_DIR/helpers" ]] && echo "    ✓ helpers/"
    [[ -f "$SHARED_DIR/overview.md" ]] && echo "    ✓ overview.md"
else
    echo "  ✗ Shared directory does not exist"
    echo "    Run /analysis.init to create it"
fi

# Check current topic structure
echo ""
if [[ -d "$TOPIC_DIR" ]]; then
    echo "  ✓ Current topic directory exists"
    [[ -f "$TOPIC_DIR/overview.md" ]] && echo "    ✓ overview.md"
    [[ -f "$TOPIC_DIR/server.md" ]] && echo "    ✓ server.md"
    [[ -f "$TOPIC_DIR/client.md" ]] && echo "    ✓ client.md"
    [[ -d "$TOPIC_DIR/features" ]] && echo "    ✓ features/"
    [[ -d "$TOPIC_DIR/apis" ]] && echo "    ✓ apis/"
    
    # Count feature and api files
    if [[ -d "$TOPIC_DIR/features" ]]; then
        FEATURE_COUNT=$(find "$TOPIC_DIR/features" -type f -name "*.md" | wc -l | tr -d ' ')
        echo "    📝 Features: $FEATURE_COUNT"
    fi
    
    if [[ -d "$TOPIC_DIR/apis" ]]; then
        API_COUNT=$(find "$TOPIC_DIR/apis" -type f -name "*.md" | wc -l | tr -d ' ')
        echo "    🔌 APIs: $API_COUNT"
    fi
else
    if [[ "$CURRENT_BRANCH" =~ ^analysis/ ]]; then
        echo "  ✗ Current topic directory does not exist"
        echo "    Expected: $TOPIC_DIR"
        echo "    This might be a new branch. Run /analysis.init if needed."
    else
        echo "  - Not on an analysis branch"
    fi
fi

# Check templates
echo ""
echo "Templates Status:"
if [[ -d "$TEMPLATES_DIR" ]]; then
    echo "  ✓ Templates directory exists"
    
    TEMPLATES=(
        "overview-template.md"
        "server-template.md"
        "client-template.md"
        "feature-template.md"
        "api-template.md"
        "component-template.md"
        "helper-template.md"
        "request-pipeline-template.md"
    )
    
    for template in "${TEMPLATES[@]}"; do
        if [[ -f "$TEMPLATES_DIR/$template" ]]; then
            echo "    ✓ $template"
        else
            echo "    ✗ $template (missing)"
        fi
    done
else
    echo "  ✗ Templates directory not found"
fi

# Check constitution
echo ""
echo "Constitution Status:"
if [[ -f "$CONSTITUTION_FILE" ]]; then
    echo "  ✓ constitution.md exists"
    LINE_COUNT=$(wc -l < "$CONSTITUTION_FILE")
    echo "    Lines: $LINE_COUNT"
else
    echo "  ✗ constitution.md not found"
fi

echo ""
echo "=== End of Environment Info ==="

