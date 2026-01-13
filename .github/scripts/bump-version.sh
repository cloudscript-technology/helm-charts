#!/bin/bash
set -euo pipefail

# Script to bump chart version
# Usage: ./bump-version.sh <chart-name> <version-type>
# version-type: major, minor, patch

CHART_NAME="${1:-}"
VERSION_TYPE="${2:-patch}"

if [ -z "$CHART_NAME" ]; then
  echo "Usage: $0 <chart-name> [major|minor|patch]"
  echo "Example: $0 deploy-apps minor"
  exit 1
fi

if [ ! -d "$CHART_NAME" ]; then
  echo "Error: Chart directory '$CHART_NAME' not found"
  exit 1
fi

CHART_FILE="$CHART_NAME/Chart.yaml"

if [ ! -f "$CHART_FILE" ]; then
  echo "Error: Chart.yaml not found in $CHART_NAME"
  exit 1
fi

# Get current version
CURRENT_VERSION=$(grep '^version:' "$CHART_FILE" | awk '{print $2}')

if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: Could not find version in $CHART_FILE"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version based on type
case "$VERSION_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Error: Invalid version type. Use: major, minor, or patch"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "New version: $NEW_VERSION"

# Update Chart.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$CHART_FILE"
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION/" "$CHART_FILE"
fi

echo ""
echo "✓ Version bumped successfully!"
echo "Chart: $CHART_NAME"
echo "Old version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Review the change: git diff $CHART_FILE"
echo "2. Commit: git add $CHART_FILE && git commit -m 'chore($CHART_NAME): bump version to $NEW_VERSION'"
echo "3. Push: git push origin main"
