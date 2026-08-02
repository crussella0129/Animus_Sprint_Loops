[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

function Assert-Contract {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw "adapter-contract.windows: FAIL: $Message"
    }
}

function Assert-ExpectedFailure {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        [Parameter(Mandatory)]
        [string]$Message
    )

    $failed = $false
    try {
        & $Action
    } catch {
        $failed = $true
    }
    Assert-Contract $failed $Message
}

function Assert-NoTransactionArtifacts {
    param([Parameter(Mandatory)][string]$Destination)

    $parent = Split-Path -Parent $Destination
    $artifacts = @(
        Get-ChildItem -Force -LiteralPath $parent -ErrorAction Stop |
            Where-Object {
                $_.Name -like '.sprint-loops.install-*' -or
                $_.Name -like '.sprint-loops.backup-*' -or
                $_.Name -eq '.sprint-loops.install.lock'
            }
    )
    Assert-Contract ($artifacts.Count -eq 0) `
        "clean transaction left artifacts under $parent"
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path
$readmePath = Join-Path $root 'codex-cli\README.md'
$readme = Get-Content -Raw -LiteralPath $readmePath -ErrorAction Stop
$functionBlock = [regex]::Match(
    $readme,
    '(?s)```powershell\r?\n(function Install-SprintLoopsSkill.*?\r?\n)\s*```'
)
Assert-Contract $functionBlock.Success `
    'documented PowerShell installer function was not found'
Invoke-Expression $functionBlock.Groups[1].Value

$source = Join-Path $root 'codex-cli\skills\sprint-loops'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'sprint-loops-powershell-contract-' + [guid]::NewGuid().ToString('N')
)
$originalLocation = Get-Location

try {
    New-Item -ItemType Directory -Force -Path $tempRoot `
        -ErrorAction Stop | Out-Null
    Set-Location -LiteralPath $tempRoot -ErrorAction Stop

    # Source and destination are independent and both tolerate spaces.
    $normalDestination = Join-Path $tempRoot `
        'normal case\home with spaces\.agents\skills\sprint-loops'
    Install-SprintLoopsSkill -Source $source -Destination $normalDestination
    Assert-Contract (
        Test-Path -LiteralPath (Join-Path $normalDestination 'SKILL.md')
    ) 'PowerShell install omitted SKILL.md'
    Assert-Contract (
        -not (Test-Path -LiteralPath (
            Join-Path $normalDestination '.sprint-loops.install-owner'
        ))
    ) 'PowerShell install retained its transaction marker'
    Set-Content -LiteralPath (Join-Path $normalDestination 'stale.txt') `
        -Value stale -ErrorAction Stop
    Install-SprintLoopsSkill -Source $source -Destination $normalDestination
    Assert-Contract (
        -not (Test-Path -LiteralPath (Join-Path $normalDestination 'stale.txt'))
    ) 'PowerShell reinstall retained stale content'
    Assert-NoTransactionArtifacts $normalDestination

    # A recovery/concurrency lock refuses a second mutation.
    $normalParent = Split-Path -Parent $normalDestination
    $heldLock = Join-Path $normalParent '.sprint-loops.install.lock'
    New-Item -ItemType Directory -Path $heldLock -ErrorAction Stop | Out-Null
    Set-Content -LiteralPath (Join-Path $heldLock 'owner') `
        -Value recovery-required -NoNewline -ErrorAction Stop
    Assert-ExpectedFailure {
        Install-SprintLoopsSkill -Source $source `
            -Destination $normalDestination
    } 'PowerShell installer ignored an existing transaction lock'
    Assert-Contract (
        Test-Path -LiteralPath (Join-Path $normalDestination 'SKILL.md')
    ) 'lock refusal mutated the installed skill'
    Microsoft.PowerShell.Management\Remove-Item -Recurse -Force `
        -LiteralPath $heldLock -ErrorAction Stop

    # A partial Copy-Item failure leaves the prior install and no transaction.
    $copyDestination = Join-Path $tempRoot `
        'copy failure\.agents\skills\sprint-loops'
    Install-SprintLoopsSkill -Source $source -Destination $copyDestination
    Set-Content -LiteralPath (Join-Path $copyDestination 'known-good.txt') `
        -Value copy -ErrorAction Stop
    function global:Copy-Item {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$LiteralPath,
            [Parameter(Mandatory)][string]$Destination,
            [switch]$Recurse,
            [switch]$Force
        )
        Microsoft.PowerShell.Management\New-Item -ItemType Directory `
            -Force -Path $Destination -ErrorAction Stop | Out-Null
        Microsoft.PowerShell.Management\Set-Content `
            -LiteralPath (Join-Path $Destination 'partial.txt') `
            -Value partial -ErrorAction Stop
        throw 'injected Copy-Item failure'
    }
    try {
        Assert-ExpectedFailure {
            Install-SprintLoopsSkill -Source $source `
                -Destination $copyDestination
        } 'injected PowerShell copy failure succeeded'
    } finally {
        Microsoft.PowerShell.Management\Remove-Item `
            -LiteralPath Function:\Copy-Item -ErrorAction SilentlyContinue
    }
    Assert-Contract (
        Test-Path -LiteralPath (Join-Path $copyDestination 'known-good.txt')
    ) 'copy failure changed the prior install'
    Assert-NoTransactionArtifacts $copyDestination

    # An activation failure restores the prior install before deleting stage.
    $moveDestination = Join-Path $tempRoot `
        'move failure\.agents\skills\sprint-loops'
    Install-SprintLoopsSkill -Source $source -Destination $moveDestination
    Set-Content -LiteralPath (Join-Path $moveDestination 'known-good.txt') `
        -Value move -ErrorAction Stop
    $script:moveCalls = 0
    function global:Move-Item {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$LiteralPath,
            [Parameter(Mandatory)][string]$Destination
        )
        $script:moveCalls++
        if ($script:moveCalls -eq 2) {
            throw 'injected activation failure'
        }
        Microsoft.PowerShell.Management\Move-Item `
            -LiteralPath $LiteralPath -Destination $Destination `
            -ErrorAction Stop
    }
    try {
        Assert-ExpectedFailure {
            Install-SprintLoopsSkill -Source $source `
                -Destination $moveDestination
        } 'injected PowerShell activation failure succeeded'
    } finally {
        Microsoft.PowerShell.Management\Remove-Item `
            -LiteralPath Function:\Move-Item -ErrorAction SilentlyContinue
    }
    Assert-Contract (
        Test-Path -LiteralPath (Join-Path $moveDestination 'known-good.txt')
    ) 'activation failure did not restore the prior install'
    Assert-NoTransactionArtifacts $moveDestination

    # A foreign destination at cutover is preserved with the known-good backup.
    $collisionDestination = Join-Path $tempRoot `
        'external collision\.agents\skills\sprint-loops'
    Install-SprintLoopsSkill -Source $source `
        -Destination $collisionDestination
    Set-Content -LiteralPath (Join-Path $collisionDestination 'known-good.txt') `
        -Value collision -ErrorAction Stop
    $collisionHold = Join-Path $tempRoot 'collision staged tree'
    $script:collisionMoveCalls = 0
    function global:Move-Item {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$LiteralPath,
            [Parameter(Mandatory)][string]$Destination
        )
        $script:collisionMoveCalls++
        if ($script:collisionMoveCalls -eq 2) {
            Microsoft.PowerShell.Management\Move-Item `
                -LiteralPath $LiteralPath -Destination $collisionHold `
                -ErrorAction Stop
            Microsoft.PowerShell.Management\New-Item -ItemType Directory `
                -Force -Path $Destination -ErrorAction Stop | Out-Null
            Microsoft.PowerShell.Management\Set-Content `
                -LiteralPath (Join-Path $Destination 'intruder.txt') `
                -Value intruder -ErrorAction Stop
            Microsoft.PowerShell.Management\Set-Content `
                -LiteralPath (
                    Join-Path $Destination '.sprint-loops.install-owner'
                ) -Value foreign -NoNewline -ErrorAction Stop
            throw 'injected external destination collision'
        }
        Microsoft.PowerShell.Management\Move-Item `
            -LiteralPath $LiteralPath -Destination $Destination `
            -ErrorAction Stop
    }
    try {
        Assert-ExpectedFailure {
            Install-SprintLoopsSkill -Source $source `
                -Destination $collisionDestination
        } 'external PowerShell destination collision succeeded'
    } finally {
        Microsoft.PowerShell.Management\Remove-Item `
            -LiteralPath Function:\Move-Item -ErrorAction SilentlyContinue
    }
    Assert-Contract (
        Test-Path -LiteralPath (Join-Path $collisionDestination 'intruder.txt')
    ) 'PowerShell rollback deleted an unowned destination'
    $collisionParent = Split-Path -Parent $collisionDestination
    $collisionBackup = @(
        Get-ChildItem -Force -LiteralPath $collisionParent |
            Where-Object Name -Like '.sprint-loops.backup-*'
    )
    Assert-Contract ($collisionBackup.Count -eq 1) `
        'PowerShell collision did not preserve exactly one backup'
    Assert-Contract (
        Test-Path -LiteralPath (
            Join-Path $collisionBackup[0].FullName 'known-good.txt'
        )
    ) 'PowerShell collision corrupted its known-good backup'
    Assert-Contract (
        Test-Path -LiteralPath (
            Join-Path $collisionParent '.sprint-loops.install.lock'
        )
    ) 'PowerShell collision did not retain a recovery lock'

    # Links and junctions are refused without touching their targets.
    $linkDestination = Join-Path $tempRoot `
        'reparse case\.agents\skills\sprint-loops'
    $linkParent = Split-Path -Parent $linkDestination
    $linkTarget = Join-Path $tempRoot 'reparse target'
    New-Item -ItemType Directory -Force -Path $linkParent, $linkTarget `
        -ErrorAction Stop | Out-Null
    Set-Content -LiteralPath (Join-Path $linkTarget 'sentinel.txt') `
        -Value keep -ErrorAction Stop
    if ($env:OS -eq 'Windows_NT') {
        New-Item -ItemType Junction -Path $linkDestination `
            -Target $linkTarget -ErrorAction Stop | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $linkDestination `
            -Target $linkTarget -ErrorAction Stop | Out-Null
    }
    Assert-ExpectedFailure {
        Install-SprintLoopsSkill -Source $source `
            -Destination $linkDestination
    } 'PowerShell installer replaced a reparse-point target'
    Assert-Contract (
        Test-Path -LiteralPath (Join-Path $linkTarget 'sentinel.txt')
    ) 'PowerShell installer mutated a reparse target'

    'adapter-contract.windows: PowerShell installer fixtures passed'
} finally {
    Microsoft.PowerShell.Management\Remove-Item `
        -LiteralPath Function:\Copy-Item -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Remove-Item `
        -LiteralPath Function:\Move-Item -ErrorAction SilentlyContinue
    Set-Location -LiteralPath $originalLocation
    $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
    $expectedPrefix = [IO.Path]::GetFullPath(
        (Join-Path ([IO.Path]::GetTempPath()) `
            'sprint-loops-powershell-contract-')
    )
    if (-not $resolvedTemp.StartsWith(
        $expectedPrefix,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "unsafe temporary cleanup target: $resolvedTemp"
    }
    if (Test-Path -LiteralPath $resolvedTemp) {
        Microsoft.PowerShell.Management\Remove-Item -Recurse -Force `
            -LiteralPath $resolvedTemp -ErrorAction Stop
    }
}
