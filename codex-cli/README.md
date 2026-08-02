# Sprint Loops for Codex

This directory ships one self-contained `$sprint-loops` skill for current
Codex clients. The project’s canonical state is its Book v2 under `docs/`;
the runtime-neutral contract is in
[`phases/00-overview.md`](skills/sprint-loops/phases/00-overview.md), and the
intent lifecycle is in
[`schemas/intent.md`](skills/sprint-loops/schemas/intent.md).

## Choose one installation scope

Codex discovers standalone skills from `$HOME/.agents/skills` and from
`.agents/skills` between the launch directory and repository root. Same-name
skills are not merged, so install either the user copy or the project copy for
a given project unless two visible `$sprint-loops` entries are intentional.

### POSIX or Bash

User installation:

```bash
bash codex-cli/install.sh
# $HOME/.agents/skills/sprint-loops
```

Project installation (run anywhere inside the target Git repository):

```bash
bash codex-cli/install.sh --project
# $REPO_ROOT/.agents/skills/sprint-loops
```

Inside Git, `--project` resolves the top level. Outside Git, it treats the
physical current directory as the workspace root; when Git is unavailable,
run it from the intended root. Filesystem and Windows drive roots are refused.
Unknown or trailing arguments are rejected. An existing symlink or
non-directory target is preserved and refused; a regular prior install is
replaced transactionally. Concurrent or interrupted transactions retain a
protective sibling lock until recovery is unambiguous.

### Native Windows PowerShell

Use this exact-destination installer function, then choose one invocation:

```powershell
function Install-SprintLoopsSkill {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    $markerName = '.sprint-loops.install-owner'
    $source = (Resolve-Path -LiteralPath $Source -ErrorAction Stop).Path
    $sourceItem = Get-Item -Force -LiteralPath $source -ErrorAction Stop
    if (-not $sourceItem.PSIsContainer -or
        ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Install source must be a regular directory."
    }
    Get-Item -Force -LiteralPath (Join-Path $source 'SKILL.md') `
        -ErrorAction Stop | Out-Null
    if (Test-Path -LiteralPath (Join-Path $source $markerName)) {
        throw "Install source uses reserved transaction marker: $markerName"
    }

    $Destination = [IO.Path]::GetFullPath($Destination)
    $parent = [IO.Path]::GetDirectoryName($Destination)
    $leaf = [IO.Path]::GetFileName($Destination)
    $id = [guid]::NewGuid().ToString('N')
    $stage = Join-Path $parent ".$leaf.install-$id"
    $backup = Join-Path $parent ".$leaf.backup-$id"
    $lock = Join-Path $parent ".$leaf.install.lock"
    $owner = Join-Path $lock 'owner'
    $lockHeld = $false
    $priorMoved = $false
    $activating = $false
    $committed = $false
    $safeToUnlock = $false
    $postCommitCleanupPending = $false

    $getEntry = {
        param([string]$EntryParent, [string]$EntryLeaf)
        Get-ChildItem -Force -LiteralPath $EntryParent -ErrorAction Stop |
            Where-Object Name -EQ $EntryLeaf |
            Select-Object -First 1
    }

    New-Item -ItemType Directory -Force -Path $parent `
        -ErrorAction Stop | Out-Null
    try {
        try {
            New-Item -ItemType Directory -Path $lock `
                -ErrorAction Stop | Out-Null
        } catch {
            throw "Another install or a recovery lock owns ${lock}: $($_.Exception.Message)"
        }
        $lockHeld = $true
        Set-Content -LiteralPath $owner -Value $id -NoNewline `
            -ErrorAction Stop

        $item = & $getEntry $parent $leaf
        if ($null -ne $item) {
            if (-not $item.PSIsContainer -or
                ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Refusing to replace a link or non-directory target."
            }
        }

        Copy-Item -Recurse -LiteralPath $source -Destination $stage `
            -ErrorAction Stop
        $stageItem = Get-Item -Force -LiteralPath $stage -ErrorAction Stop
        $stageSkill = Get-Item -Force -LiteralPath (Join-Path $stage 'SKILL.md') `
            -ErrorAction Stop
        if (-not $stageItem.PSIsContainer -or
            ($stageItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
            $stageSkill.PSIsContainer -or
            ($stageSkill.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Staged install is not a self-contained regular skill."
        }
        Set-Content -LiteralPath (Join-Path $stage $markerName) `
            -Value $id -NoNewline -ErrorAction Stop

        $item = & $getEntry $parent $leaf
        if ($null -ne $item) {
            if (-not $item.PSIsContainer -or
                ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Target changed into a link or non-directory."
            }
            Move-Item -LiteralPath $Destination -Destination $backup `
                -ErrorAction Stop
            $priorMoved = $true
        }

        $activating = $true
        Move-Item -LiteralPath $stage -Destination $Destination `
            -ErrorAction Stop
        $activating = $false
        $committed = $true
        try {
            Remove-Item -Force `
                -LiteralPath (Join-Path $Destination $markerName) `
                -ErrorAction Stop
        } catch {
            $postCommitCleanupPending = $true
            Write-Warning "Skill is installed, but its ownership marker remains."
        }

        if ($priorMoved) {
            try {
                Remove-Item -Recurse -Force -LiteralPath $backup `
                    -ErrorAction Stop
                $priorMoved = $false
            } catch {
                $postCommitCleanupPending = $true
                Write-Warning "Skill is installed, but cleanup remains at $backup."
            }
        }
        $safeToUnlock = -not $postCommitCleanupPending
    } catch {
        $primary = $_
        $rollbackProblems = [System.Collections.Generic.List[string]]::new()

        if (-not $committed -and $activating -and
            -not (Test-Path -LiteralPath $stage) -and
            ($null -ne (& $getEntry $parent $leaf))) {
            $ownedDestination = $false
            try {
                $marker = Get-Item -Force `
                    -LiteralPath (Join-Path $Destination $markerName) `
                    -ErrorAction Stop
                if (-not $marker.PSIsContainer -and
                    -not ($marker.Attributes -band
                        [IO.FileAttributes]::ReparsePoint) -and
                    ((Get-Content -Raw -LiteralPath $marker.FullName `
                        -ErrorAction Stop) -eq $id)) {
                    $ownedDestination = $true
                }
            } catch {
                $ownedDestination = $false
            }
            if ($ownedDestination) {
                try {
                    Move-Item -LiteralPath $Destination -Destination $stage `
                        -ErrorAction Stop
                } catch {
                    $rollbackProblems.Add(
                        "could not quarantine interrupted destination: $($_.Exception.Message)")
                }
            } else {
                $rollbackProblems.Add(
                    "unowned destination preserved with any backup under $lock")
            }
        }

        if (-not $committed -and $priorMoved -and
            (Test-Path -LiteralPath $backup)) {
            if ($null -eq (& $getEntry $parent $leaf)) {
                try {
                    Move-Item -LiteralPath $backup -Destination $Destination `
                        -ErrorAction Stop
                    $priorMoved = $false
                } catch {
                    $rollbackProblems.Add(
                        "prior install remains at ${backup}: $($_.Exception.Message)")
                }
            } else {
                $rollbackProblems.Add(
                    "unexpected destination; prior install preserved at $backup")
            }
        }

        if (Test-Path -LiteralPath $stage) {
            try {
                $stageItem = Get-Item -Force -LiteralPath $stage `
                    -ErrorAction Stop
                if ($stageItem.Attributes -band
                    [IO.FileAttributes]::ReparsePoint) {
                    throw "staging root became a reparse point"
                }
                Remove-Item -Recurse -Force -LiteralPath $stage `
                    -ErrorAction Stop
            } catch {
                $rollbackProblems.Add(
                    "staging cleanup failed at ${stage}: $($_.Exception.Message)")
            }
        }

        if (-not $committed -and (Test-Path -LiteralPath $backup)) {
            $rollbackProblems.Add("recovery evidence remains at $backup")
        }
        if ($rollbackProblems.Count -eq 0) {
            $safeToUnlock = $true
        } else {
            throw "$($primary.Exception.Message) Rollback: $($rollbackProblems -join '; ')"
        }
        throw $primary
    } finally {
        if ($lockHeld -and $safeToUnlock) {
            try {
                if (Test-Path -LiteralPath $owner) {
                    Remove-Item -Force -LiteralPath $owner -ErrorAction Stop
                }
                Remove-Item -Force -LiteralPath $lock -ErrorAction Stop
            } catch {
                Write-Warning "Recovery lock could not be removed: $lock"
            }
        } elseif ($lockHeld) {
            Write-Warning "Transaction evidence remains protected by $lock."
        }
    }
}
```

User scope:

```powershell
$bundleSource = (Resolve-Path '.\codex-cli\skills\sprint-loops').Path
Install-SprintLoopsSkill -Source $bundleSource `
    -Destination (Join-Path $HOME '.agents\skills\sprint-loops')
```

Project scope, from anywhere in a Git repository containing this bundle:

```powershell
$repoRoot = (& git rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0) { throw 'Run from a Git repository.' }
$bundleSource = Join-Path $repoRoot 'codex-cli\skills\sprint-loops'
Install-SprintLoopsSkill -Source $bundleSource `
    -Destination (Join-Path $repoRoot '.agents\skills\sprint-loops')
```

For a separate target repository, resolve `$bundleSource` from this checkout
and pass the target repository’s absolute `.agents\skills\sprint-loops` path as
`-Destination`; source and destination are intentionally independent.

Native Windows and WSL have different home directories. A user install run
inside WSL targets the WSL user, not native Windows Codex. Project installs
under `/mnt/c/...` and native paths address the same repository files, so do
not run native and WSL installers concurrently against one project.

The deterministic helpers require Bash at runtime. Native Windows Codex should
use Git for Windows Bash, which understands a resolved `C:/...` skill path.
WSL Bash is supported when Codex itself runs inside WSL and discovers the skill
through `/home/...` or `/mnt/c/...`; merely exposing WSL Bash to native Codex
does not translate a native skill path.

## Activate and verify

Invoke the skill explicitly with `$sprint-loops`, or directly ask Codex to
start, continue, resume, or run Sprint Loops. Ordinary documentation work and
the mere presence of `docs/` do not activate it.

Codex detects skill changes automatically. If the skill does not appear, start
a new session. Confirm that `$sprint-loops` appears once; if it appears twice,
remove either the user- or project-scoped copy.

**Human/client checkpoint:** in that new session, verify the skill appears
once, activates for a direct sprint request, and remains inactive for unrelated
documentation work. This discovery behavior cannot be proven by static bundle
tests.

The bundled [`AGENTS.md.fragment`](skills/sprint-loops/AGENTS.md.fragment) is
an optional short project pointer. Merge it into the project’s `AGENTS.md`
once if durable discoverability helps. Skill discovery does not require that
fragment, and blindly appending it on every install would duplicate guidance.
Because project instructions load at session start, open a new session after
changing `AGENTS.md`.

## Authority profile

A `preauthorized-remote profile` is a Sprint Loops term, not a Codex built-in
permission profile. It must be issued by the user or operator and bound the
repository/remote, allowed operation classes, target refs or environments,
preconditions, scope, and stop conditions. The agent cannot create, infer, or
broaden one. General requests for autonomy and permissive sandbox settings do
not constitute that profile.

Operator setup stays in this README. Routing stays in
[`SKILL.md`](skills/sprint-loops/SKILL.md); phase behavior stays in `phases/`;
the Book remains the cross-session and cross-harness authority.
