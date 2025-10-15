#!/usr/bin/env bash
#
# Legacy wrapper script for backward compatibility.
# This script now redirects to analysis-create-architecture.sh --create-components
#
set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show deprecation warning
echo "⚠️  Note: This script is deprecated and will be removed in a future version."
echo "    Please use: /analysis-create-architecture instead."
echo ""

# Redirect to new script
exec "$SCRIPT_DIR/analysis-create-architecture.sh" --create-components
