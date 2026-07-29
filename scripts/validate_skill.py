#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pyyaml>=6,<7",
# ]
# ///

"""Run Codex's built-in skill validator with its YAML dependency."""

from __future__ import annotations

import os
from pathlib import Path
import runpy
import sys


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: validate_skill.py <skill-directory>")

    codex_home = Path(
        os.environ.get("CODEX_HOME", Path.home() / ".codex")
    ).expanduser()
    validator = (
        codex_home
        / "skills"
        / ".system"
        / "skill-creator"
        / "scripts"
        / "quick_validate.py"
    )
    if not validator.is_file():
        raise SystemExit(f"Codex skill validator not found: {validator}")

    skill_directory = Path(sys.argv[1]).expanduser().resolve()
    if not skill_directory.is_dir():
        raise SystemExit(f"Skill directory not found: {skill_directory}")

    sys.argv = [str(validator), str(skill_directory)]
    runpy.run_path(str(validator), run_name="__main__")


if __name__ == "__main__":
    main()
