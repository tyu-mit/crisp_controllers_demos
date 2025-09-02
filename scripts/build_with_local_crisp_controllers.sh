#!/bin/bash

# Build script for using local crisp_controllers
# Usage: ./scripts/build_with_local_crisp_controllers.sh [CRISP_CONTROLLERS_PATH] [TARGET]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMOS_DIR="$(dirname "$SCRIPT_DIR")"

# Show usage if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [CRISP_CONTROLLERS_PATH] [TARGET]"
    echo ""
    echo "Arguments:"
    echo "  CRISP_CONTROLLERS_PATH  Path to crisp_controllers directory (default: ../crisp_controllers)"
    echo "  TARGET                  Docker build target (default: franka-overlay)"
    echo ""
    echo "Available targets: franka-overlay, kinova-overlay, iiwa-overlay"
    echo ""
    echo "Examples:"
    echo "  $0                                          # Use ../crisp_controllers, build franka-overlay"
    echo "  $0 /path/to/crisp_controllers              # Use specific path, build franka-overlay"
    echo "  $0 ../crisp_controllers kinova-overlay     # Use ../crisp_controllers, build kinova-overlay"
    exit 0
fi

# Default values
CRISP_CONTROLLERS_PATH="${1:-../crisp_controllers}"
TARGET="${2:-franka-overlay}"
TEMP_COPY_CREATED=false

# Function to clean up
cleanup() {
    if [ "$TEMP_COPY_CREATED" = true ] && [ -d "$DEMOS_DIR/crisp_controllers" ]; then
        echo "Cleaning up temporary copy..."
        rm -rf "$DEMOS_DIR/crisp_controllers"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Resolve absolute path if the path exists
if [ -e "$CRISP_CONTROLLERS_PATH" ]; then
    CRISP_CONTROLLERS_PATH=$(realpath "$CRISP_CONTROLLERS_PATH")
fi

echo "=== Building with Local crisp_controllers ==="
echo "crisp_controllers path: $CRISP_CONTROLLERS_PATH"
echo "Build target: $TARGET"
echo "Build context: $DEMOS_DIR"

# Check if the path exists
if [ ! -d "$CRISP_CONTROLLERS_PATH" ]; then
    echo "Error: crisp_controllers directory not found at: $CRISP_CONTROLLERS_PATH"
    echo "Please provide a valid path to crisp_controllers directory"
    exit 1
fi

# Check if it's a valid crisp_controllers directory
if [ ! -f "$CRISP_CONTROLLERS_PATH/package.xml" ] || [ ! -f "$CRISP_CONTROLLERS_PATH/CMakeLists.txt" ]; then
    echo "Error: $CRISP_CONTROLLERS_PATH doesn't appear to be a valid crisp_controllers directory"
    echo "Expected files: package.xml, CMakeLists.txt"
    exit 1
fi

# Create symlink in build context
cd "$DEMOS_DIR"
if [ -e "crisp_controllers" ]; then
    echo "Warning: crisp_controllers already exists in build context"
    echo "Please remove it first: rm -rf crisp_controllers"
    exit 1
fi

echo "Copying crisp_controllers to build context..."
cp -r "$CRISP_CONTROLLERS_PATH" crisp_controllers
TEMP_COPY_CREATED=true

echo "Building Docker image..."
docker compose build "$TARGET"

echo "Build completed successfully!"
echo "You can now run: docker compose up $TARGET"
