#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'USAGE'
Usage:
  tools/build_android_release.sh [all|apk|aab]

Outputs:
  apk: builds armeabi-v7a 32-bit APK, arm64-v8a 64-bit APK, and universal 32+64 APK
  aab: builds one ARM 32+64 Android App Bundle
  all: builds both APKs and AAB

Optional environment overrides:
  BUILD_NAME=1.0.0
  BUILD_NUMBER=1
  RELEASE_OUTPUT_DIR=/absolute/output/dir
  GRASS_GAME_STORE_FILE=/absolute/path/app-release-key.jks
  GRASS_GAME_STORE_PASSWORD=...
  GRASS_GAME_KEY_ALIAS=...
  GRASS_GAME_KEY_PASSWORD=...
USAGE
}

MODE="${1:-all}"
case "$MODE" in
  all|apk|aab) ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

PUBSPEC_VERSION="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"
PUBSPEC_BUILD_NAME="${PUBSPEC_VERSION%%+*}"
PUBSPEC_BUILD_NUMBER="${PUBSPEC_VERSION#*+}"
if [[ "$PUBSPEC_BUILD_NUMBER" == "$PUBSPEC_VERSION" ]]; then
  PUBSPEC_BUILD_NUMBER="1"
fi

BUILD_NAME="${BUILD_NAME:-$PUBSPEC_BUILD_NAME}"
BUILD_NUMBER="${BUILD_NUMBER:-$PUBSPEC_BUILD_NUMBER}"
BUILD_DATE="$(date +%Y%m%d)"
OUTPUT_DIR="${RELEASE_OUTPUT_DIR:-$ROOT_DIR/output/$BUILD_DATE}"
APP_NAME="${APP_NAME:-flutter_game}"

export GRASS_GAME_STORE_FILE="${GRASS_GAME_STORE_FILE:-$ROOT_DIR/app-release-key.jks}"
export GRASS_GAME_STORE_PASSWORD="${GRASS_GAME_STORE_PASSWORD:-clg_app_sign}"
export GRASS_GAME_KEY_ALIAS="${GRASS_GAME_KEY_ALIAS:-app_sign}"
export GRASS_GAME_KEY_PASSWORD="${GRASS_GAME_KEY_PASSWORD:-clg_app_sign}"
export GRASS_GAME_REQUIRE_RELEASE_SIGNING=true

if [[ ! -f "$GRASS_GAME_STORE_FILE" ]]; then
  echo "Keystore not found: $GRASS_GAME_STORE_FILE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

VERSION_ARGS=(
  --build-name "$BUILD_NAME"
  --build-number "$BUILD_NUMBER"
)
TARGET_PLATFORMS="android-arm,android-arm64"

copy_required() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "$src" ]]; then
    echo "Build output not found: $src" >&2
    exit 1
  fi
  cp "$src" "$dest"
  echo "  $dest"
}

echo "Release output: $OUTPUT_DIR"
echo "Version: $BUILD_NAME+$BUILD_NUMBER"
echo "Keystore: $GRASS_GAME_STORE_FILE"
echo "Key alias: $GRASS_GAME_KEY_ALIAS"

if [[ "$MODE" == "all" || "$MODE" == "apk" ]]; then
  echo
  echo "Building split APKs: 32-bit armeabi-v7a and 64-bit arm64-v8a"
  flutter build apk \
    --release \
    --target-platform "$TARGET_PLATFORMS" \
    --split-per-abi \
    "${VERSION_ARGS[@]}"

  copy_required \
    "$ROOT_DIR/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
    "$OUTPUT_DIR/${APP_NAME}_${BUILD_NAME}_${BUILD_NUMBER}_armeabi-v7a_32bit.apk"
  copy_required \
    "$ROOT_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
    "$OUTPUT_DIR/${APP_NAME}_${BUILD_NAME}_${BUILD_NUMBER}_arm64-v8a_64bit.apk"

  echo
  echo "Building universal APK: ARM 32+64"
  flutter build apk \
    --release \
    --target-platform "$TARGET_PLATFORMS" \
    "${VERSION_ARGS[@]}"

  copy_required \
    "$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk" \
    "$OUTPUT_DIR/${APP_NAME}_${BUILD_NAME}_${BUILD_NUMBER}_universal_32_64.apk"
fi

if [[ "$MODE" == "all" || "$MODE" == "aab" ]]; then
  echo
  echo "Building AAB: one ARM 32+64 bundle"
  flutter build appbundle \
    --release \
    --target-platform "$TARGET_PLATFORMS" \
    "${VERSION_ARGS[@]}"

  copy_required \
    "$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab" \
    "$OUTPUT_DIR/${APP_NAME}_${BUILD_NAME}_${BUILD_NUMBER}_arm_32_64.aab"
fi

echo
echo "Done."
