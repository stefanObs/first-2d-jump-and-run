#!/bin/bash
# Double-click macOS updater. Downloads the newest Cowboy Trail files from GitHub.
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
export COWBOY_UPDATE_NO_PAUSE=1

pause_on_error() {
    local exit_code=$?
    printf '\nUpdate failed (error %d).\n' "$exit_code" >&2
    printf 'Press Return to close this window.\n' >&2
    read -r _ || true
    exit "$exit_code"
}
trap pause_on_error ERR

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This updater is for macOS. On Linux, run ./update_to_newest.sh instead.\n' >&2
    false
fi

cd "$PROJECT_DIR"
"$PROJECT_DIR/update_to_newest.sh"

printf '\nPress Return to close this window.\n'
read -r _ || true
