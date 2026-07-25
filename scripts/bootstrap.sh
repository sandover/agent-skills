#!/bin/bash
# Install this repository's personal skills into the shared local registry.
# Also register the selected company and tool-owned skills when their source
# repositories are present. The script only creates symlinks and refuses to
# replace existing paths, so rerunning it is safe.

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
agent_home=${AGENT_SKILLS_HOME:-$HOME}
registry="$agent_home/.agents/skills"

link_skill() {
  local destination=$1
  local source=$2

  if [ -L "$destination" ]; then
    if [ "$(readlink "$destination")" = "$source" ]; then
      printf 'already linked: %s\n' "$destination"
      return
    fi
    printf 'conflict: %s links to %s\n' "$destination" "$(readlink "$destination")" >&2
    return 1
  fi

  if [ -e "$destination" ]; then
    printf 'conflict: %s already exists\n' "$destination" >&2
    return 1
  fi

  ln -s "$source" "$destination"
  printf 'linked: %s -> %s\n' "$destination" "$source"
}

link_if_present() {
  local name=$1
  local source=$2

  if [ ! -d "$source" ]; then
    printf 'skipped (source unavailable): %s\n' "$source"
    return
  fi
  link_skill "$registry/$name" "$source"
}

mkdir -p "$registry"

for source in "$repo_dir"/skills/*; do
  [ -d "$source" ] || continue
  link_skill "$registry/$(basename "$source")" "$source"
done

link_if_present ergo-feature-planning "$agent_home/src/ergo/skills/ergo-feature-planning"
link_if_present plasmite-release-manager "$agent_home/src/plasmite/skills/plasmite-release-manager"
link_if_present shaping-github-tickets "$agent_home/src/fourier/fourier-skills/engineering/shaping-github-tickets"

mkdir -p "$agent_home/.claude" "$agent_home/.codex"
link_skill "$agent_home/.claude/skills" "$registry"
link_skill "$agent_home/.codex/skills" "$registry"
