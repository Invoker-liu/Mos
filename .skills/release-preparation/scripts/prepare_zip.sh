#!/usr/bin/env bash
# prepare_zip.sh - Package Mos.app into a release zip
# Usage: prepare_zip.sh <path-to-Mos.app> [--channel stable|beta|alpha]
# Output: JSON with zip_path, version, build, tag, zip_name
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"

die() { echo "Error: $*" >&2; exit 1; }

APP_PATH="${1:-}"
CHANNEL="stable"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel) CHANNEL="$2"; shift 2 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$APP_PATH" ]] || die "Usage: prepare_zip.sh <path-to-Mos.app> [--channel stable|beta|alpha]"
[[ -d "$APP_PATH" ]] || die "Not found: $APP_PATH"

# Read version from app's Info.plist
PLIST="$APP_PATH/Contents/Info.plist"
[[ -f "$PLIST" ]] || die "Missing Info.plist: $PLIST"

SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null) || die "Cannot read CFBundleShortVersionString"
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null) || die "Cannot read CFBundleVersion"

# Build zip filename: Mos.Versions.{version}[-(alpha|beta)]-{YYYYMMDD.N}.zip
CHANNEL_SUFFIX=""
TAG="$SHORT_VERSION"
if [[ "$CHANNEL" != "stable" ]]; then
  CHANNEL_SUFFIX="-${CHANNEL}"
  TAG="${SHORT_VERSION}-${CHANNEL}-${BUNDLE_VERSION}"
fi
ZIP_NAME="Mos.Versions.${SHORT_VERSION}${CHANNEL_SUFFIX}-${BUNDLE_VERSION}.zip"

mkdir -p "$BUILD_DIR"
ZIP_PATH="$BUILD_DIR/$ZIP_NAME"

# Create zip (ditto preserves macOS metadata)
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

FILE_LENGTH=$(wc -c < "$ZIP_PATH" | tr -d '[:space:]')

cat <<EOF
{
  "zip_path": "$ZIP_PATH",
  "zip_name": "$ZIP_NAME",
  "version": "$SHORT_VERSION",
  "build": "$BUNDLE_VERSION",
  "channel": "$CHANNEL",
  "tag": "$TAG",
  "length": $FILE_LENGTH
}
EOF
