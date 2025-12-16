#!/bin/bash
# Apply OpenWebRX patches to installed Python packages
# Run this script inside Docker container at startup

set -e

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIRS=(
    "/usr/lib/python3/dist-packages"
    "/usr/local/lib/python3.*/dist-packages"
)

# Find the actual target directory
TARGET_DIR=""
for pattern in "${TARGET_DIRS[@]}"; do
    for dir in $pattern; do
        if [ -d "$dir/owrx" ]; then
            TARGET_DIR="$dir"
            break 2
        fi
    done
done

if [ -z "$TARGET_DIR" ]; then
    echo "Error: Could not find owrx installation directory"
    exit 1
fi

echo "Target directory: $TARGET_DIR"

# Initialize git if needed (for patch to work)
cd "$TARGET_DIR"
if [ ! -d ".git" ]; then
    echo "Initializing git repository in $TARGET_DIR..."
    git init -q
    git add -A
    git commit -q -m "Initial state" --allow-empty
fi

# Apply patches
for patch_file in "$PATCH_DIR"/*.patch; do
    if [ -f "$patch_file" ]; then
        patch_name=$(basename "$patch_file")
        echo "Applying patch: $patch_name"

        # Check if patch can be applied
        if git apply --check "$patch_file" 2>/dev/null; then
            git apply "$patch_file"
            echo "  Applied successfully"
        elif git apply --check -R "$patch_file" 2>/dev/null; then
            echo "  Already applied, skipping"
        else
            echo "  Warning: Patch may have conflicts, trying with --3way..."
            git apply --3way "$patch_file" || echo "  Failed to apply $patch_name"
        fi
    fi
done

echo "Patch process completed"
