#!/usr/bin/env bash
# Update Cowboy Trail to the newest files from GitHub.
# Works on Linux and macOS with no extra packages (uses Python 3, or curl/wget).
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_UPDATER="$PROJECT_DIR/tools/update_to_newest.py"

pause_on_error() {
    local exit_code=$?
    if [[ "${COWBOY_UPDATE_NO_PAUSE:-}" == "1" ]]; then
        exit "$exit_code"
    fi
    printf '\nUpdate failed (error %d).\n' "$exit_code" >&2
    if [[ -t 0 ]]; then
        printf 'Press Return to close.\n' >&2
        read -r _ || true
    fi
    exit "$exit_code"
}
trap pause_on_error ERR

if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
    printf 'Keep update_to_newest.sh inside the Cowboy Trail game folder.\n' >&2
    false
fi

find_python() {
    local candidate
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)' \
                2>/dev/null; then
                command -v "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

download_with_shell() {
    local url="$1"
    local dest="$2"
    local partial="${dest}.part"
    rm -f "$partial"
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --retry 3 --connect-timeout 20 \
            --progress-bar "$url" --output "$partial"
    elif command -v wget >/dev/null 2>&1; then
        wget --timeout=120 --tries=3 -O "$partial" "$url"
    else
        printf 'Need Python 3, curl, or wget to download the update.\n' >&2
        return 1
    fi
    mv "$partial" "$dest"
}

fallback_shell_update() {
    local url="https://github.com/stefanObs/first-2d-jump-and-run/archive/refs/heads/main.zip"
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/cowboy_trail_update.XXXXXX")"
    cleanup() { rm -rf "$tmp"; }
    trap cleanup EXIT

    printf 'Python 3 not found; using curl/wget fallback...\n'
    download_with_shell "$url" "$tmp/cowboy-trail-main.zip"

    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$tmp/cowboy-trail-main.zip" -d "$tmp/extracted"
    elif command -v ditto >/dev/null 2>&1; then
        mkdir -p "$tmp/extracted"
        ditto -x -k "$tmp/cowboy-trail-main.zip" "$tmp/extracted"
    else
        printf 'Need unzip (or ditto on macOS) for the fallback updater.\n' >&2
        return 1
    fi

    local package
    package="$(find "$tmp/extracted" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -z "$package" || ! -f "$package/project.godot" ]]; then
        printf 'Update package looks invalid.\n' >&2
        return 1
    fi

    # Prefer the Python path for a correct preserve/sync; this fallback uses rsync/cp.
    printf 'Applying update (fallback copy)...\n'
    if command -v rsync >/dev/null 2>&1; then
        rsync -a \
            --exclude 'savegames/' \
            --exclude '.git/' \
            --exclude '.godot/' \
            --exclude 'godot/macos/' \
            --exclude 'dist/' \
            --exclude 'Play Cowboy Trail.exe' \
            --exclude 'godot/*.exe' \
            "$package"/ "$PROJECT_DIR"/
    else
        # Best-effort overwrite of common trees without deleting local-only files.
        local name
        for name in assets scenes scripts tests tools godot docs \
            project.godot content_version.txt README.md icon.png icon.svg icon.ico \
            run_linux.sh run_windows.bat create_exe.sh create_exe.bat \
            "Play Cowboy Trail.bat" "Play Cowboy Trail.command" \
            update_to_newest.sh update_to_newest.bat \
            "Update to Newest Version.command"; do
            if [[ -e "$package/$name" ]]; then
                rm -rf "$PROJECT_DIR/$name"
                cp -R "$package/$name" "$PROJECT_DIR/$name"
            fi
        done
    fi
    rm -rf "$PROJECT_DIR/.godot"
    printf '\nUpdate applied (fallback). Start the game as usual to refresh assets.\n'
}

PYTHON_BIN="$(find_python || true)"
if [[ -n "$PYTHON_BIN" && -f "$PY_UPDATER" ]]; then
    exec "$PYTHON_BIN" "$PY_UPDATER" --path "$PROJECT_DIR"
fi

fallback_shell_update
