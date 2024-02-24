#!/bin/bash

# Remember the initial directory
INITIAL_DIR=$(pwd)

# Function to return to the initial directory
function return_to_initial_dir {
  cd "$INITIAL_DIR" || exit
}

# Navigate to the project root directory if the script is located in a subdirectory
# cd "$(dirname "$0")/.."

# Read version from pubspec.yaml
VERSION=$(awk '/version: / {print $2}' pubspec.yaml)

APPNAME=mc_rcon_client

if [ -z "$VERSION" ]; then
  echo "Version not found in pubspec.yaml"
  return_to_initial_dir
  exit 1
fi

echo "Building version $VERSION"

# Run Flutter build for Linux
flutter build linux --release

# Check if the build was successful
if [ $? -ne 0 ]; then
  echo "Flutter build failed"
  return_to_initial_dir
  exit 1
fi

# Navigate to the build output directory
cd build/linux/x64/release/bundle || exit

# Create a tarball with the app version included in the filename
tar -czvf "../../../$APPNAME-$VERSION-linux-x64.tar.gz" *

echo "Package $APPNAME-$VERSION-linux-x64.tar.gz created successfully"

# Return to the initial directory
return_to_initial_dir
