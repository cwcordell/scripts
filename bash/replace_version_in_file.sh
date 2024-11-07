#!/bin/bash

# Usage: ./replace_version_in_file.sh <file_path> <new_version>
# Example: ./replace_version_in_file.sh path/to/file.js 4.2.0
set -e

FILE_PATH=$1
NEW_VERSION=$2
ERRORS=0

if [[ -z "$FILE_PATH" ]]; then
    echo "Error: expected argument for FILE_PATH."
    ERRORS=$((ERRORS + 1))
fi

if [[ -z "$NEW_VERSION" ]]; then
    echo "Error: expected argument for NEW_VERSION."
    ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -gt 0 ]]; then
  echo "Usage: $0 <file_path> <new_version>" >&2
  exit 1
fi

echo "Displaying $FILE_PATH before update..."
cat $FILE_PATH

echo
echo "Updating $FILE_PATH with new $NEW_VERSION version ..."

sed -i '' "s/export const AIS_RELEASEVERSION = '.*';/export const AIS_RELEASEVERSION = '$NEW_VERSION';/" "$FILE_PATH"

# Check if the file was updated properly
if grep -q "export const AIS_RELEASEVERSION = '$NEW_VERSION';" "$FILE_PATH"; then
  echo "Version updated to $NEW_VERSION in $FILE_PATH"
else
  echo "Failed to update the version in $FILE_PATH"
  exit 1
fi

echo "Displaying $FILE_PATH after update..."
cat $FILE_PATH