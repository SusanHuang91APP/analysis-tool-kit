#!/usr/bin/env bash
#
# Prints all important paths for the current analysis environment.
# Useful for debugging. Inspired by spec-kit's get-feature-paths.sh.
#
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

eval $(get_analysis_paths)

check_analysis_branch "$CURRENT_BRANCH" || exit 1

echo "--- Analysis Paths for $CURRENT_BRANCH ---"
echo "REPO_ROOT:          $REPO_ROOT"
echo "KIT_DIR:            $KIT_DIR"
echo "KIT_PARENT_DIR:     $KIT_PARENT_DIR"
echo "PAGE_ANALYSIS_DIR:  $PAGE_ANALYSIS_DIR"
echo "OVERVIEW_FILE:      $OVERVIEW_FILE"
echo "README_FILE:        $README_FILE"
echo "CONSTITUTION_FILE:  $CONSTITUTION_FILE"
echo "------------------------------------"