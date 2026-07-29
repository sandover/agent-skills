# Agent Skills

Brandon's personal skills, shared across machines and available to both Codex
and Claude.

## Machine setup

Clone this repository to `~/src/agent-skills`. Use `~/.agents/skills` as the
machine's skill registry, and make both `~/.codex/skills` and
`~/.claude/skills` resolve to that registry.

Link skills into the registry from their actual source:

- Personal skills come from this repository's `skills/` directory.
- Company skills stay in the company skills repository.
- Tool-bundled skills stay in the tool's repository.
- Project skills stay in the project that owns them.

Inspect the machine's existing skill directories before changing them. Preserve
useful skills and avoid maintaining copied versions of source-owned skills.

## Skill validation

Validate a skill with the personal wrapper:

```bash
uv run ~/src/agent-skills/scripts/validate_skill.py <skill-directory>
```

The wrapper supplies PyYAML to Codex's built-in skill validator from an isolated
cached environment. Application repositories do not need a Python project or a
global PyYAML installation for skill validation.
