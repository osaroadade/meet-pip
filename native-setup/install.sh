#!/bin/bash

# Native Messaging Host Installer
# Copies the manifest to the Chrome NativeMessagingHosts directory

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST_NAME="com.meetpip.app"
TARGET_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"

echo "Installing Native Messaging Host: $HOST_NAME"

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy manifest
cp "$DIR/$HOST_NAME.json" "$TARGET_DIR/"

echo "Installed manifest to $TARGET_DIR/$HOST_NAME.json"
echo "NOTE: You must start the MeetPIP app build at least once to ensure the binary exists."
