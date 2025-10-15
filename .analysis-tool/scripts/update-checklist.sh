#!/usr/bin/env bash
#
# Automatically update quality level checklist in block files based on actual content
# This script checks real content and updates checkboxes accordingly
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
eval $(get_analysis_paths)

# --- Parse Arguments ---
BLOCK_FILE="$1"
if [[ -z "$BLOCK_FILE" ]]; then
    log_error "Usage: $0 <block-file.md>"
    exit 1
fi

if [[ ! -f "$BLOCK_FILE" ]]; then
    log_error "Block file not found: $BLOCK_FILE"
    exit 1
fi

log_info "Updating checklist for: $(basename "$BLOCK_FILE")"

# --- Quality Check Functions ---

# Check if content line count meets threshold
check_content_lines() {
    local file="$1"
    local threshold="$2"
    local actual=$(grep -v -E '^\s*$|^\s*#|^\s*\[待補充|^\s*\[自動填入|^\s*-\s*\[\s*\]|^\s*>\s*\*\*' "$file" | wc -l)
    [[ $actual -ge $threshold ]]
}

# Check if file has non-empty code blocks
check_real_html() {
    local file="$1"
    grep -q "### 1\.1 HTML 結構" "$file" && \
    grep -A 20 "### 1\.1 HTML 結構" "$file" | grep -q "\`\`\`html" && \
    ! grep -A 20 "### 1\.1 HTML 結構" "$file" | grep -q "\`\`\`html\s*\`\`\`"
}

# Check if file has real mermaid diagrams
check_real_mermaid() {
    local file="$1"
    grep -q "sequenceDiagram" "$file" && \
    grep -A 10 "sequenceDiagram" "$file" | grep -q "participant\|User->>View"
}

# Check if file has specific CSS content
check_css_analysis() {
    local file="$1"
    grep -q "CSS.*class\|\.TG-header\|\.tool\|\.caution" "$file"
}

# Check if file has accessibility content
check_accessibility() {
    local file="$1"
    grep -q "a11y\|無障礙\|Accessibility\|ARIA\|tabindex\|aria-" "$file"
}

# Check if file has real TypeScript content
check_real_typescript() {
    local file="$1"
    grep -q "typescript\|javascript" "$file" && \
    ! grep -q "exampleMethod\|待補充.*typescript" "$file" && \
    local count=$(grep -c "\`\`\`typescript\|\`\`\`javascript" "$file")
    [[ $count -ge 2 ]]
}

# Update checklist item
update_checklist_item() {
    local file="$1"
    local pattern="$2"
    local status="$3"  # "x" for checked, " " for unchecked
    
    sed -i.bak "s/^- \[ \] \*\*${pattern}\*\*/- [${status}] **${pattern}**/" "$file"
    sed -i.bak "s/^- \[x\] \*\*${pattern}\*\*/- [${status}] **${pattern}**/" "$file"
}

# --- Main Logic ---

# Foundation Level (⭐)
if grep -q "## 1\. 介面與互動分析" "$BLOCK_FILE" && \
   grep -q "## 2\. 實作細節分析" "$BLOCK_FILE" && \
   grep -q "## 3\. 架構與品質分析" "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "結構完整" "x"
    log_success "✓ Structure complete"
else
    update_checklist_item "$BLOCK_FILE" "結構完整" " "
fi

if check_content_lines "$BLOCK_FILE" 50; then
    update_checklist_item "$BLOCK_FILE" "基本功能描述" "x"
    log_success "✓ Basic description complete"
else
    update_checklist_item "$BLOCK_FILE" "基本功能描述" " "
fi

if grep -q "🔗 相關檔案.*\.cshtml\|🔗 相關檔案.*\.ts\|🔗 相關檔案.*\.cs" "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "檔案連結" "x"
    log_success "✓ File links complete"
else
    update_checklist_item "$BLOCK_FILE" "檔案連結" " "
fi

# UI Layer Level (⭐⭐)
if check_real_html "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "HTML結構分析" "x"
    log_success "✓ HTML structure analysis complete"
else
    update_checklist_item "$BLOCK_FILE" "HTML結構分析" " "
fi

if check_real_mermaid "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "互動流程圖" "x"
    log_success "✓ Interaction flow diagram complete"
else
    update_checklist_item "$BLOCK_FILE" "互動流程圖" " "
fi

if check_css_analysis "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "CSS樣式分析" "x"
    log_success "✓ CSS style analysis complete"
else
    update_checklist_item "$BLOCK_FILE" "CSS樣式分析" " "
fi

if check_accessibility "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "無障礙性評估" "x"
    log_success "✓ Accessibility evaluation complete"
else
    update_checklist_item "$BLOCK_FILE" "無障礙性評估" " "
fi

# Logic Layer Level (⭐⭐⭐)
if check_real_typescript "$BLOCK_FILE"; then
    update_checklist_item "$BLOCK_FILE" "Controller方法分析" "x"
    log_success "✓ Controller method analysis complete"
else
    update_checklist_item "$BLOCK_FILE" "Controller方法分析" " "
fi

# Clean up backup files
rm -f "${BLOCK_FILE}.bak"

log_success "Checklist updated for: $(basename "$BLOCK_FILE")"
