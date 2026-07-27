#!/usr/bin/env python3
"""Download the newest Cowboy Trail files from GitHub into this project folder.

Uses only the Python standard library (urllib + zipfile). No git, curl, or
extra packages required. Preserves local savegames and cached Godot engines.
"""

from __future__ import annotations

import argparse
import os
import shutil
import ssl
import sys
import tempfile
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

REPO_OWNER = "stefanObs"
REPO_NAME = "first-2d-jump-and-run"
BRANCH = "main"
ZIP_URL = (
    f"https://github.com/{REPO_OWNER}/{REPO_NAME}/archive/refs/heads/{BRANCH}.zip"
)
USER_AGENT = "CowboyTrail-Updater/1.0"

# Paths that must never be overwritten or deleted by an update.
PRESERVE_NAMES = {
    "savegames",
    ".git",
    ".godot",  # wiped separately so the next launch reimports
}

# Relative path prefixes kept as local-only caches / builds.
PRESERVE_PREFIXES = (
    "savegames/",
    ".git/",
    "godot/macos/",
    "dist/",
)


def project_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def is_preserved(rel: str) -> bool:
    rel = rel.replace("\\", "/").lstrip("./")
    if not rel:
        return True
    top = rel.split("/", 1)[0]
    if top in PRESERVE_NAMES:
        return True
    if any(rel == p.rstrip("/") or rel.startswith(p) for p in PRESERVE_PREFIXES):
        return True
    # Keep unpacked Windows Godot engine next to the bundled zip.
    if rel.startswith("godot/") and rel.lower().endswith(".exe"):
        return True
    if rel == "Play Cowboy Trail.exe":
        return True
    return False


def download_zip(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    partial = dest.with_suffix(dest.suffix + ".part")
    if partial.exists():
        partial.unlink()
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    context = ssl.create_default_context()
    print(f"Downloading newest version from GitHub ({BRANCH})...")
    print(f"  {url}")
    try:
        with urllib.request.urlopen(req, context=context, timeout=120) as response:
            total = response.headers.get("Content-Length")
            total_n = int(total) if total and total.isdigit() else None
            done = 0
            last_print = 0.0
            with partial.open("wb") as out:
                while True:
                    chunk = response.read(1024 * 256)
                    if not chunk:
                        break
                    out.write(chunk)
                    done += len(chunk)
                    now = time.time()
                    if now - last_print >= 0.4:
                        if total_n:
                            pct = min(100, int(done * 100 / total_n))
                            print(f"  {pct}% ({done // (1024 * 1024)} MB)", flush=True)
                        else:
                            print(f"  {done // (1024 * 1024)} MB...", flush=True)
                        last_print = now
    except urllib.error.HTTPError as exc:
        raise SystemExit(f"Download failed (HTTP {exc.code}): {exc.reason}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"Download failed: {exc.reason}") from exc
    partial.replace(dest)
    print("Download finished.")


def extract_zip(zip_path: Path, dest_dir: Path) -> Path:
    print("Unpacking update...")
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(dest_dir)
    # GitHub archive layout: <repo>-<branch>/
    children = [p for p in dest_dir.iterdir() if p.is_dir()]
    if len(children) != 1:
        raise SystemExit(
            f"Unexpected zip layout in {dest_dir} "
            f"(expected one folder, found {len(children)})."
        )
    root = children[0]
    if not (root / "project.godot").is_file():
        raise SystemExit(f"Update package is missing project.godot in {root}")
    return root


def iter_files(root: Path):
    for path in root.rglob("*"):
        if path.is_file():
            yield path


def sync_update(source_root: Path, target_root: Path) -> tuple[int, int]:
    """Copy package files into target; remove obsolete non-preserved files."""
    source_files: dict[str, Path] = {}
    for path in iter_files(source_root):
        rel = path.relative_to(source_root).as_posix()
        if is_preserved(rel):
            continue
        source_files[rel] = path

    removed = 0
    for path in list(iter_files(target_root)):
        rel = path.relative_to(target_root).as_posix()
        if is_preserved(rel):
            continue
        if rel not in source_files:
            path.unlink(missing_ok=True)
            removed += 1
            # Clean empty parent dirs (but never climb into preserve tops).
            parent = path.parent
            while parent != target_root and parent.exists():
                try:
                    parent.rmdir()
                except OSError:
                    break
                parent = parent.parent

    copied = 0
    for rel, src in sorted(source_files.items()):
        dest = target_root / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        copied += 1
    return copied, removed


def wipe_import_cache(target_root: Path) -> None:
    godot_cache = target_root / ".godot"
    if godot_cache.exists():
        print("Clearing local Godot import cache so the next launch refreshes assets...")
        shutil.rmtree(godot_cache, ignore_errors=True)


def read_version(root: Path) -> str:
    stamp = root / "content_version.txt"
    if stamp.is_file():
        return stamp.read_text(encoding="utf-8").strip()
    return "(unknown)"


def run_update(target_root: Path) -> int:
    target_root = target_root.resolve()
    if not (target_root / "project.godot").is_file():
        print(
            f"No project.godot in {target_root}.\n"
            "Keep this updater inside the Cowboy Trail game folder.",
            file=sys.stderr,
        )
        return 1

    before = read_version(target_root)
    print(f"Current content version: {before}")
    print(f"Game folder: {target_root}")

    with tempfile.TemporaryDirectory(prefix="cowboy_trail_update_") as tmp:
        tmp_path = Path(tmp)
        zip_path = tmp_path / "cowboy-trail-main.zip"
        download_zip(ZIP_URL, zip_path)
        package_root = extract_zip(zip_path, tmp_path / "extracted")
        after = read_version(package_root)
        print(f"Newest content version: {after}")
        copied, removed = sync_update(package_root, target_root)
        wipe_import_cache(target_root)

    print()
    print(f"Updated {copied} files ({removed} obsolete local files removed).")
    print(f"Content version: {before} → {after}")
    print("Savegames and cached Godot engines were kept.")
    print("Start the game with the usual Play / run script; it will reimport assets.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Update Cowboy Trail to the newest version from GitHub."
    )
    parser.add_argument(
        "--path",
        type=Path,
        default=None,
        help="Game folder to update (default: repository root next to tools/).",
    )
    args = parser.parse_args(argv)
    root = args.path if args.path is not None else project_root_from_script()
    return run_update(root)


if __name__ == "__main__":
    sys.exit(main())
