#!/usr/bin/env python3
"""Static validation for this skills repository."""

from __future__ import annotations

import os
import re
import stat
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IGNORED_DIRS = {
    ".git",
    ".github",
    ".idea",
    ".vscode",
    "__pycache__",
    "docs",
    "scripts",
}
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER_RE = re.compile(r"^---\n(?P<body>.*?)\n---\n", re.DOTALL)


def parse_frontmatter(text: str) -> dict[str, str]:
    match = FRONTMATTER_RE.match(text)
    if not match:
        return {}

    data: dict[str, str] = {}
    current_key: str | None = None
    for raw_line in match.group("body").splitlines():
        if raw_line.startswith((" ", "\t")) and current_key:
            continuation = raw_line.strip()
            if continuation:
                data[current_key] = f"{data[current_key]} {continuation}".strip()
            continue
        line = raw_line.strip()
        if not line or line.startswith("#") or ":" not in line:
            current_key = None
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and value:
            data[key] = value
            current_key = key if value in {">", "|"} else None
        else:
            current_key = None
    return data


def is_executable(path: Path) -> bool:
    return bool(path.stat().st_mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))


def check_skill_dir(path: Path) -> list[str]:
    errors: list[str] = []
    warnings: list[str] = []
    rel = path.relative_to(ROOT)

    if not NAME_RE.match(path.name):
        errors.append(f"{rel}: directory name should be kebab-case")

    skill_file = path / "SKILL.md"
    if not skill_file.exists():
        errors.append(f"{rel}: missing SKILL.md")
        return errors

    text = skill_file.read_text(encoding="utf-8")
    meta = parse_frontmatter(text)
    if not meta:
        errors.append(f"{skill_file.relative_to(ROOT)}: missing YAML frontmatter")
        return errors

    name = meta.get("name")
    slug = meta.get("slug")
    description = meta.get("description")

    if not name:
        errors.append(f"{skill_file.relative_to(ROOT)}: missing frontmatter field 'name'")
    elif name != path.name and slug != path.name:
        warnings.append(
            f"{skill_file.relative_to(ROOT)}: name '{name}' does not match directory '{path.name}'"
        )

    if not description:
        errors.append(f"{skill_file.relative_to(ROOT)}: missing frontmatter field 'description'")
    elif len(description) < 20:
        warnings.append(f"{skill_file.relative_to(ROOT)}: description is very short")

    if not (path / "README.md").exists():
        warnings.append(f"{rel}: missing README.md")

    for script in sorted((path / "scripts").glob("*")) if (path / "scripts").exists() else []:
        if not script.is_file():
            continue
        script_rel = script.relative_to(ROOT)
        first_line = script.read_text(encoding="utf-8", errors="replace").splitlines()[:1]
        shebang = first_line[0] if first_line else ""
        if script.suffix in {".sh", ".py"} and not shebang.startswith("#!"):
            errors.append(f"{script_rel}: missing shebang")
        if script.suffix in {".sh", ".py"} and not is_executable(script):
            warnings.append(f"{script_rel}: script is not executable")

    return errors + [f"WARN: {warning}" for warning in warnings]


def discover_skill_dirs() -> list[Path]:
    dirs: list[Path] = []
    for child in sorted(ROOT.iterdir()):
        if not child.is_dir() or child.name in IGNORED_DIRS or child.name.startswith("."):
            continue
        dirs.append(child)
    return dirs


def main() -> int:
    messages: list[str] = []
    skill_dirs = discover_skill_dirs()

    if not skill_dirs:
        print("No skill directories found.")
        return 1

    for skill_dir in skill_dirs:
        messages.extend(check_skill_dir(skill_dir))

    errors = [msg for msg in messages if not msg.startswith("WARN:")]
    warnings = [msg for msg in messages if msg.startswith("WARN:")]

    for msg in errors + warnings:
        print(msg)

    print(f"\nChecked {len(skill_dirs)} skill(s): {len(errors)} error(s), {len(warnings)} warning(s).")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
