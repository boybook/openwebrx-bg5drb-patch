#!/bin/bash
# Apply OpenWebRX patches to installed Python packages
# Run this script inside Docker container at startup
# Uses `patch` command (no git required)

# Scan both script directory and /opt/patch for patch files
# This supports both manual execution and Docker container startup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_DIRS=("$SCRIPT_DIR" "/opt/patch")

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
cd "$TARGET_DIR"

# Apply patches from all patch directories
declare -A applied_patches  # Track applied patches to avoid duplicates

for patch_dir in "${PATCH_DIRS[@]}"; do
    [ -d "$patch_dir" ] || continue

    for patch_file in "$patch_dir"/*.patch; do
        [ -f "$patch_file" ] || continue

        patch_name=$(basename "$patch_file")

        # Skip if already processed from another directory
        if [ "${applied_patches[$patch_name]}" = "1" ]; then
            continue
        fi
        applied_patches[$patch_name]=1

        echo "Applying patch: $patch_name (from $patch_dir)"

        # Check if patch is already applied (dry-run reverse)
        if patch -p1 -R --dry-run < "$patch_file" >/dev/null 2>&1; then
            echo "  Already applied, skipping"
        # Check if patch can be applied (dry-run forward)
        elif patch -p1 --dry-run < "$patch_file" >/dev/null 2>&1; then
            patch -p1 < "$patch_file"
            echo "  Applied successfully"
        else
            echo "  Warning: Patch may have conflicts or cannot be applied"
            patch -p1 --dry-run < "$patch_file" || true
        fi
    done
done

echo "Patch process completed"
