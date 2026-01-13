#!/bin/bash
set -euo pipefail

# Script to prepare a chart release locally
# Usage: ./prepare-release.sh <chart-name>

CHART_NAME="${1:-}"

if [ -z "$CHART_NAME" ]; then
  echo "Usage: $0 <chart-name>"
  echo "Example: $0 deploy-apps"
  exit 1
fi

if [ ! -d "$CHART_NAME" ]; then
  echo "Error: Chart directory '$CHART_NAME' not found"
  exit 1
fi

echo "==> Preparing release for $CHART_NAME"

cd "$CHART_NAME"

# Run helm lint
echo "==> Running helm lint..."
helm lint .

# Run helm dependency build
echo "==> Building dependencies..."
helm dependency build . || echo "No dependencies to build"

# Package the chart
echo "==> Packaging chart..."
cd ..
helm package "$CHART_NAME" -d /tmp/

# Get version from Chart.yaml
VERSION=$(grep '^version:' "$CHART_NAME/Chart.yaml" | awk '{print $2}')
PACKAGE_FILE="/tmp/${CHART_NAME}-${VERSION}.tgz"

# Generate SHA256
if [ -f "$PACKAGE_FILE" ]; then
  SHA256=$(shasum -a 256 "$PACKAGE_FILE" | awk '{print $1}')
  echo ""
  echo "==> Release prepared successfully!"
  echo "Chart: $CHART_NAME"
  echo "Version: $VERSION"
  echo "Package: $PACKAGE_FILE"
  echo "SHA256: $SHA256"
  echo ""
  echo "Next steps:"
  echo "1. Commit your changes: git add . && git commit -m 'Release $CHART_NAME $VERSION'"
  echo "2. Push to main: git push origin main"
  echo "3. GitHub Actions will automatically create a release"
else
  echo "Error: Package file not found"
  exit 1
fi
