# Agent Skills

Personal skills shared across Brandon's machines. Keep company, project, and
tool-owned skills in the repository that owns them.

On a new machine, clone this repository to `~/src/agent-skills` and run:

```bash
./scripts/bootstrap.sh
```

The script links personal skills into `~/.agents/skills`, makes Claude and
Codex use that registry, and links the selected company and tool skills when
their source repositories are present. It creates symlinks only and refuses to
overwrite an existing path.
