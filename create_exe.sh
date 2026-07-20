#!/usr/bin/env bash
# Build a portable Windows .exe (no install required).
# Output: dist/windows/CowboyTrail.exe (+ savegames created next to it at runtime)
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$PROJECT_DIR/dist/windows"
EXE_NAME="CowboyTrail.exe"
EXPORT_PRESET="Windows Desktop"
GODOT_VERSION="4.4.1.stable"
TEMPLATE_VERSION="4.4.1-stable"
TEMPLATE_URL="https://github.com/godotengine/godot/releases/download/${TEMPLATE_VERSION}/Godot_v${TEMPLATE_VERSION}_export_templates.tpz"

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
	printf 'Godot 4 was not found. Install it, add it to PATH, or set GODOT_BIN.\n' >&2
	return 1
}

templates_dir() {
	if [[ "$(uname -s)" == "Darwin" ]]; then
		printf '%s\n' "$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}"
	else
		printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}"
	fi
}

ensure_windows_templates() {
	local dir marker
	dir="$(templates_dir)"
	marker="$dir/version.txt"
	if [[ -f "$dir/windows_release_x86_64.exe" ]]; then
		return 0
	fi
	printf 'Downloading Godot %s Windows export templates...\n' "$GODOT_VERSION"
	mkdir -p "$dir"
	local tmp tpz
	tmp="$(mktemp -d)"
	tpz="$tmp/templates.tpz"
	if command -v curl >/dev/null 2>&1; then
		curl -L --fail --progress-bar -o "$tpz" "$TEMPLATE_URL"
	elif command -v wget >/dev/null 2>&1; then
		wget -O "$tpz" "$TEMPLATE_URL"
	else
		printf 'Need curl or wget to download export templates.\n' >&2
		rm -rf "$tmp"
		return 1
	fi
	unzip -q -o "$tpz" -d "$tmp"
	# tpz contains a templates/ folder with the binaries.
	if [[ -d "$tmp/templates" ]]; then
		cp -a "$tmp/templates/." "$dir/"
	else
		printf 'Unexpected export template archive layout.\n' >&2
		rm -rf "$tmp"
		return 1
	fi
	printf '%s\n' "$GODOT_VERSION" >"$marker"
	rm -rf "$tmp"
	if [[ ! -f "$dir/windows_release_x86_64.exe" ]]; then
		printf 'Windows release template missing after download: %s\n' "$dir" >&2
		return 1
	fi
}

write_export_presets() {
	local out="$PROJECT_DIR/export_presets.cfg"
	local export_path="$DIST_DIR/$EXE_NAME"
	cat >"$out" <<EOF
[preset.0]

name="${EXPORT_PRESET}"
platform="Windows Desktop"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="savegames/*, dist/*, godot/*, *.bat, *.sh, tests/*, .git/*"
export_path="${export_path}"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=0
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=true
application/icon="res://icon.ico"
application/console_wrapper_icon="res://icon.ico"
application/icon_interpolation=0
application/file_version="1.3.6.0"
application/product_version="1.3.6.0"
application/company_name="Cowboy Trail"
application/product_name="Cowboy Trail"
application/file_description="A friendly cowboy jump-and-run for kids"
application/copyright=""
application/trademarks=""
application/export_angle=0
application/export_d3d12=0
application/d3d12_agility_sdk_multiarch=true
ssh_remote_deploy/enabled=false
ssh_remote_deploy/host="user@host_ip"
ssh_remote_deploy/port="22"
ssh_remote_deploy/extra_args_ssh=""
ssh_remote_deploy/extra_args_scp=""
ssh_remote_deploy/run_script=""
ssh_remote_deploy/cleanup_script=""
EOF
}

write_readme() {
	cat >"$DIST_DIR/README.txt" <<'EOF'
Cowboy Trail — portable Windows build
=====================================

Double-click CowboyTrail.exe to play. No installation required.

Your progress is stored in a "savegames" folder next to this exe.
Copy the whole folder (exe + savegames) to keep progress when moving PCs.
EOF
}

main() {
	local godot
	godot="$(find_godot)"
	ensure_windows_templates
	mkdir -p "$DIST_DIR"
	write_export_presets
	write_readme
	printf 'Exporting %s ...\n' "$EXE_NAME"
	"$godot" --headless --path "$PROJECT_DIR" --export-release "$EXPORT_PRESET" "$DIST_DIR/$EXE_NAME"
	if [[ ! -f "$DIST_DIR/$EXE_NAME" ]]; then
		printf 'Export failed: %s not found.\n' "$DIST_DIR/$EXE_NAME" >&2
		exit 1
	fi
	if [[ -f "$PROJECT_DIR/icon.ico" ]]; then
		cp -f "$PROJECT_DIR/icon.ico" "$DIST_DIR/icon.ico"
	fi
	printf '\nDone.\n'
	printf 'Portable build: %s\n' "$DIST_DIR/$EXE_NAME"
	printf 'Saves will appear beside the exe in: savegames/\n'
}

main "$@"
