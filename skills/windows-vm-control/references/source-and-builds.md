# Source and builds

Establish the intended source and the installed application's architecture before choosing a build. Guest OS, application, and artifact architectures are distinct: an ARM64 Windows VM can host x86 Acrobat, which needs an x86 plugin. That result does not prove an x64 release build.

## Put an exact revision in Windows

Prefer the repository's existing remote when it already contains the revision. Fetch and verify the full commit ID. Use a new detached worktree for a build-only task, or a named task branch/worktree when the guest should implement changes. A dirty primary checkout can remain untouched while a new worktree is added.

When the revision exists only on the Mac, use a bundle with a named ref. Do not push solely to transfer source. The example below creates a task-owned temporary bare repository so the source checkout needs no temporary branch.

Fill in an observed local source repository, full candidate SHA, and full base SHA known to exist in the guest repository. The base must be an ancestor of the candidate. Run this host-only helper on the Mac:

```bash
source_repo='/absolute/host/project'
candidate='FULL_CANDIDATE_SHA'
guest_base='FULL_GUEST_BASE_SHA'
bundle_info=$(scripts/windows-vm-source-bundle "$source_repo" "$candidate" "$guest_base")
printf '%s\n' "$bundle_info"
```

The helper verifies both full IDs name commits, confirms the guest base is an ancestor, and creates a bundle in a unique task-owned temporary directory with a temporary bare repository. It reads Git objects from the source repository and does not read or change working-tree files. It checks every Git command and verifies that the bundle advertises exactly the candidate SHA under `refs/heads/candidate`. Its JSON output includes `bundle_path`, `advertised_ref`, `candidate_sha`, and `guest_base_sha`. If candidate equals base, it reports `status: already_present` and returns no bundle; skip the transfer and use the exact candidate already in the guest.

When the helper reports `bundle_created`, transfer its bundle to a unique guest filename and record the host path for the handoff:

```bash
bundle_path=$(printf '%s\n' "$bundle_info" | python3 -c 'import json,sys; print(json.load(sys.stdin)["bundle_path"])')
scp "$bundle_path" "windows-vm:$(basename "$(dirname "$bundle_path")").bundle"
```

This relative SCP destination is in the SSH account's home. Resolve its absolute Windows path rather than assuming a username. With the correct paths, run the following through the PowerShell helper or give it to the guest executor:

```powershell
$ErrorActionPreference = 'Stop'
$repo = 'C:\src\project'
$bundle = 'C:\Users\WINDOWS_USER\windows-source.UNIQUE.bundle'
$worktree = 'C:\src\project-proof-UNIQUE'
$candidate = 'FULL_CANDIDATE_SHA'
& git -C $repo bundle verify $bundle
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& git -C $repo fetch $bundle refs/heads/candidate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$received = & git -C $repo rev-parse FETCH_HEAD
if ($LASTEXITCODE -ne 0 -or $received -ne $candidate) { throw 'Unexpected candidate' }
& git -C $repo worktree add --detach $worktree $candidate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& git -C $worktree rev-parse HEAD
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& git -C $worktree status --short
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

A prerequisite failure means the guest lacks history required by the bundle. Fetch the missing history from the existing remote or recreate the bundle against a verified shared base. Do not substitute a different revision, reset the user's checkout, or expand to every local branch without a reason. Coordinate repository metadata changes with any existing owner.

Keep transfer files until the guest verifies receipt. Remove only this task's transfer files afterward. Retain the worktree while its outputs or changes are needed; do not force-remove a dirty worktree as cleanup.

## Build and return useful proof

Use the project's supported command and existing SDK/dependency locations. Set profile, target architecture, and build-only/install options explicitly in the guest process. Inspect the script's actual options before relying on an environment variable from a handoff.

Return the requested evidence, usually:

- Exact source SHA and any local modifications used in the build.
- Command, target architecture/profile, exit status, and first failing phase if applicable.
- Artifact path, architecture, and SHA-256 when identifying or transferring a binary.
- Installation/load status only if those steps were authorized and checked.

A successful compiler phase followed by a failed installer wrapper is a partial result. Report both and preserve the artifact evidence. A failing source-text test on Windows may be a line-ending assumption; diagnose that failure without weakening its intended assertion.

For an authorized replacement, preserve the existing installed artifact/settings needed for recovery, install the new artifact, and compare installed and built hashes. Then check application load or behavior if required. Ask the user for a quick file-opening or login step when useful; the agent remains responsible for build and verification.
