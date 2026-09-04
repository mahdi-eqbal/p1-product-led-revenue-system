#!/usr/bin/env python3

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(".").resolve()

EXCLUDED_DIRECTORIES = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    "dist",
    "build",
}

LINK_PATTERN = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")

errors = []
markdown_files = []
checked_links = 0

for markdown_file in sorted(Path(".").rglob("*.md")):
    if any(part in EXCLUDED_DIRECTORIES for part in markdown_file.parts):
        continue

    markdown_files.append(markdown_file)

    try:
        content = markdown_file.read_text(encoding="utf-8-sig")
    except Exception as exc:
        errors.append(f"{markdown_file}: could not read file: {exc}")
        continue

    for match in LINK_PATTERN.finditer(content):
        raw_target = match.group(1).strip()

        if not raw_target:
            continue

        if raw_target.startswith("<") and ">" in raw_target:
            target = raw_target[1:raw_target.index(">")]
        else:
            target = raw_target.split(maxsplit=1)[0]

        if (
            target.startswith("#")
            or target.startswith("//")
            or target.startswith("mailto:")
            or target.startswith("tel:")
            or target.startswith("data:")
        ):
            continue

        parsed = urlsplit(target)

        if parsed.scheme in {"http", "https"}:
            continue

        relative_path = unquote(parsed.path)

        if not relative_path:
            continue

        checked_links += 1
        resolved_path = (markdown_file.parent / relative_path).resolve()

        try:
            resolved_path.relative_to(ROOT)
        except ValueError:
            errors.append(
                f"{markdown_file}: link points outside repository: {target}"
            )
            continue

        if not resolved_path.exists():
            errors.append(
                f"{markdown_file}: missing local target: {target}"
            )

print(f"Scanned {len(markdown_files)} Markdown file(s).")
print(f"Checked {checked_links} local link(s) and image reference(s).")

if errors:
    print("\nBroken local references detected:")

    for error in errors:
        print(f"- {error}")

    sys.exit(1)

print("All local Markdown references are valid.")
