#!/bin/bash

# Native Messaging Host Installer
# Copies the manifest to the Chrome NativeMessagingHosts directory

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST_NAME="com.meetpip.app"
TARGET_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
PROJECT_ROOT="$(dirname "$DIR")"

# Load configuration from .env
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
fi

# Validate EXTENSION_ID
if [ -z "$EXTENSION_ID" ]; then
    echo "ERROR: EXTENSION_ID is not set."
    echo "Please create a .env file in the project root with the following content:"
    echo "EXTENSION_ID=your_extension_id_here"
    echo ""
    echo "You can find the ID in chrome://extensions/ after loading the unpacked extension."
    exit 1
fi

# Calculate the absolute path to the binary
# Assumes the script is in 'native-setup' and the binary is in the standard DerivedData location relative to the project root
# Modify this path if your build output location changes
BINARY_PATH="$PROJECT_ROOT/meet-pip/DerivedData/Build/Products/Debug/meetpip.app/Contents/MacOS/meetpip"

if [ ! -f "$BINARY_PATH" ]; then
    echo "WARNING: Binary not found at $BINARY_PATH"
    echo "Please run 'make build-app' first to build the Xcode project."
fi

echo "Installing Native Messaging Host: $HOST_NAME"
echo "Extension ID: $EXTENSION_ID"
echo "Binary Path: $BINARY_PATH"

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Generate the manifest with the correct path and extension ID
sed -e "s|REPLACE_WITH_ABSOLUTE_PATH|$BINARY_PATH|g" \
    -e "s|REPLACE_WITH_EXTENSION_ID|$EXTENSION_ID|g" \
    "$DIR/$HOST_NAME.json" > "$TARGET_DIR/$HOST_NAME.json"

echo "Installed manifest to $TARGET_DIR/$HOST_NAME.json"
echo "NOTE: You must start the MeetPIP app build at least once to ensure the binary exists."
