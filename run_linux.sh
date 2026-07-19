#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

find_godot() {
    if [[ -n "${GODOT_BIN:-}" ]]; then
        if [[ -x "$GODOT_BIN" ]]; then
            printf '%s\n' "$GODOT_BIN"
            return 0
        fi
        if command -v "$GODOT_BIN" >/dev/null 2>&1; then
            command -v "$GODOT_BIN"
            return 0
        fi
        printf 'GODOT_BIN does not point to an executable: %s\n' "$GODOT_BIN" >&2
        return 1
    fi

    local candidate
    for candidate in godot4 godot "$HOME/.local/bin/godot"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    printf '%s\n' \
        'Godot 4 was not found. Install it, add it to PATH, or set GODOT_BIN.' >&2
    return 1
}

GODOT_EXECUTABLE="$(find_godot)"
exec "$GODOT_EXECUTABLE" --path "$PROJECT_DIR" "$@"
