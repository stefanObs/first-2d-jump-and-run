#!/bin/bash
set -Eeuo pipefail

# Double-click macOS launcher. Godot is downloaded into the project on first
# launch, so the player does not need to install Godot or another dependency.

PROJECT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
GODOT_VERSION="4.4.1-stable"
GODOT_DIR="$PROJECT_DIR/godot/macos"
GODOT_APP="$GODOT_DIR/Godot.app"
GODOT_EXECUTABLE="$GODOT_APP/Contents/MacOS/Godot"
GODOT_ZIP="$GODOT_DIR/Godot_v${GODOT_VERSION}_macos.universal.zip"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_macos.universal.zip"
STAMP_FILE="$PROJECT_DIR/content_version.txt"
CACHE_STAMP="$PROJECT_DIR/.godot/cowboy_trail_content_version.txt"

pause_on_error() {
    local exit_code=$?
    printf '\nCowboy Trail could not start (error %d).\n' "$exit_code" >&2
    printf 'Press Return to close this window.\n' >&2
    read -r _ || true
    exit "$exit_code"
}
trap pause_on_error ERR

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This launcher is for macOS. On Linux, run ./run_linux.sh instead.\n' >&2
    false
fi

cd "$PROJECT_DIR"

if [[ ! -x "$GODOT_EXECUTABLE" ]]; then
    mkdir -p "$GODOT_DIR"
    if [[ ! -f "$GODOT_ZIP" ]]; then
        printf '\nFirst start: downloading the Godot game engine (about 127 MB)...\n'
        printf 'An internet connection is needed only for this first download.\n\n'
        partial_zip="${GODOT_ZIP}.part"
        rm -f "$partial_zip"
        curl --fail --location --retry 3 --connect-timeout 20 \
            --progress-bar "$GODOT_URL" --output "$partial_zip"
        mv "$partial_zip" "$GODOT_ZIP"
    fi

    printf '\nPreparing the game engine...\n'
    rm -rf "$GODOT_APP"
    if command -v ditto >/dev/null 2>&1; then
        ditto -x -k "$GODOT_ZIP" "$GODOT_DIR"
    else
        /usr/bin/unzip -q "$GODOT_ZIP" -d "$GODOT_DIR"
    fi
    chmod +x "$GODOT_EXECUTABLE"
fi

if [[ ! -x "$GODOT_EXECUTABLE" ]]; then
    printf 'Godot could not be prepared in: %s\n' "$GODOT_DIR" >&2
    false
fi

need_import=0
if [[ ! -d "$PROJECT_DIR/.godot" ]]; then
    need_import=1
elif [[ ! -f "$STAMP_FILE" || ! -f "$CACHE_STAMP" ]]; then
    need_import=1
elif ! cmp -s "$STAMP_FILE" "$CACHE_STAMP"; then
    need_import=1
fi

if [[ "$need_import" -eq 1 ]]; then
    printf '\nUpdating Cowboy Trail to the latest checked-out version...\n\n'
    rm -rf "$PROJECT_DIR/.godot"
    "$GODOT_EXECUTABLE" --headless --path "$PROJECT_DIR" --import
    mkdir -p "$PROJECT_DIR/.godot"
    cp "$STAMP_FILE" "$CACHE_STAMP"
fi

printf '\nStarting Cowboy Trail...\n'
exec "$GODOT_EXECUTABLE" --path "$PROJECT_DIR"
