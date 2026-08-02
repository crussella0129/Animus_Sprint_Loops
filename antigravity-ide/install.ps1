<#
.SYNOPSIS
Installs the Sprint Loops workflow and runtime skill for Antigravity IDE.

.DESCRIPTION
Stages and activates both Antigravity surfaces under the official user config:

  ~/.gemini/config/global_workflows/sprint-loops.md
  ~/.gemini/config/skills/sprint-loop/

Existing installations are backed up inside the transaction and restored if
either activation fails.

.PARAMETER ConfigRoot
Overrides the Antigravity config root. The default is ~/.gemini/config. This is
also useful for isolated installation tests.
#>

[CmdletBinding()]
param(
    [string]$ConfigRoot = (Join-Path -Path ([Environment]::GetFolderPath("UserProfile")) -ChildPath ".gemini\config")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-SafePathChain {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $fullPath = [System.IO.Path]::GetFullPath($LiteralPath)
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    if ([string]::IsNullOrWhiteSpace($root)) {
        throw "$Label has no filesystem root: $LiteralPath"
    }

    $rootItem = Get-Item -Force -LiteralPath $root
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Label traverses a reparse-point root: $root"
    }

    $separators = [char[]]@(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $segments = $fullPath.Substring($root.Length).Split(
        $separators,
        [System.StringSplitOptions]::RemoveEmptyEntries
    )
    $comparison = if (
        [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    ) {
        [System.StringComparison]::OrdinalIgnoreCase
    }
    else {
        [System.StringComparison]::Ordinal
    }
    $current = $root

    for ($index = 0; $index -lt $segments.Length; $index++) {
        $segment = $segments[$index]
        $matches = @(
            Get-ChildItem -Force -LiteralPath $current |
                Where-Object {
                    [string]::Equals($_.Name, $segment, $comparison)
                }
        )
        if ($matches.Count -eq 0) {
            break
        }
        if ($matches.Count -ne 1) {
            throw "$Label has an ambiguous path component '$segment': $fullPath"
        }

        $item = $matches[0]
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label traverses a reparse point: $($item.FullName)"
        }
        if ($index -lt ($segments.Length - 1) -and -not $item.PSIsContainer) {
            throw "$Label traverses a non-directory component: $($item.FullName)"
        }
        $current = $item.FullName
    }
}

if ([string]::IsNullOrWhiteSpace($ConfigRoot)) {
    throw "ConfigRoot must not be empty."
}

$sourceWorkflow = Join-Path -Path $PSScriptRoot -ChildPath "global_workflows\sprint-loops.md"
$sourceSkill = Join-Path -Path $PSScriptRoot -ChildPath "skills\sprint-loop"
$requiredSources = @(
    $sourceWorkflow,
    (Join-Path -Path $sourceSkill -ChildPath "SKILL.md"),
    (Join-Path -Path $sourceSkill -ChildPath "scripts\current-phase.sh"),
    (Join-Path -Path $sourceSkill -ChildPath "schemas\intent.md")
)

foreach ($requiredSource in $requiredSources) {
    if (-not (Test-Path -LiteralPath $requiredSource -PathType Leaf)) {
        throw "Required Antigravity bundle file is missing: $requiredSource"
    }
}

$configRootPath = [System.IO.Path]::GetFullPath($ConfigRoot)
$pathRoot = [System.IO.Path]::GetPathRoot($configRootPath)
$trimChars = [char[]]@(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
)
if ($configRootPath.TrimEnd($trimChars) -eq $pathRoot.TrimEnd($trimChars)) {
    throw "Refusing to use a filesystem root as ConfigRoot: $configRootPath"
}

$workflowDirectory = Join-Path -Path $configRootPath -ChildPath "global_workflows"
$workflowDestination = Join-Path -Path $workflowDirectory -ChildPath "sprint-loops.md"
$skillsDirectory = Join-Path -Path $configRootPath -ChildPath "skills"
$skillDestination = Join-Path -Path $skillsDirectory -ChildPath "sprint-loop"
$lockPath = Join-Path -Path $configRootPath -ChildPath ".sprint-loops-install.lock"
$transactionPath = Join-Path -Path $configRootPath -ChildPath (".sprint-loops-install-" + [Guid]::NewGuid().ToString("N"))

# Validate every existing component, including dangling links discoverable by
# directory enumeration, before the installer creates anything.
Assert-SafePathChain -LiteralPath $configRootPath -Label "Antigravity config root"
Assert-SafePathChain -LiteralPath $workflowDestination -Label "Sprint Loops workflow destination"
Assert-SafePathChain -LiteralPath $skillDestination -Label "Sprint Loops skill destination"
Assert-SafePathChain -LiteralPath $lockPath -Label "Sprint Loops install lock"
Assert-SafePathChain -LiteralPath $transactionPath -Label "Sprint Loops transaction"

$lockAcquired = $false
$transactionCreated = $false
$skillBackedUp = $false
$workflowBackedUp = $false
$skillActivated = $false
$workflowActivated = $false
$preserveTransaction = $false

try {
    New-Item -ItemType Directory -Force -Path $configRootPath | Out-Null
    Assert-SafePathChain -LiteralPath $configRootPath -Label "Antigravity config root"

    New-Item -ItemType Directory -Path $lockPath | Out-Null
    $lockAcquired = $true
    Assert-SafePathChain -LiteralPath $lockPath -Label "Sprint Loops install lock"

    New-Item -ItemType Directory -Path $transactionPath | Out-Null
    $transactionCreated = $true
    Assert-SafePathChain -LiteralPath $transactionPath -Label "Sprint Loops transaction"

    $stagedWorkflow = Join-Path -Path $transactionPath -ChildPath "sprint-loops.md"
    $stagedSkill = Join-Path -Path $transactionPath -ChildPath "sprint-loop"
    $backupWorkflow = Join-Path -Path $transactionPath -ChildPath "backup-sprint-loops.md"
    $backupSkill = Join-Path -Path $transactionPath -ChildPath "backup-sprint-loop"

    Copy-Item -LiteralPath $sourceWorkflow -Destination $stagedWorkflow
    Copy-Item -LiteralPath $sourceSkill -Destination $stagedSkill -Recurse

    foreach ($stagedRequirement in @(
        $stagedWorkflow,
        (Join-Path -Path $stagedSkill -ChildPath "SKILL.md"),
        (Join-Path -Path $stagedSkill -ChildPath "scripts\current-phase.sh"),
        (Join-Path -Path $stagedSkill -ChildPath "schemas\intent.md")
    )) {
        if (-not (Test-Path -LiteralPath $stagedRequirement -PathType Leaf)) {
            throw "Staged Antigravity bundle is incomplete: $stagedRequirement"
        }
    }

    Assert-SafePathChain -LiteralPath $workflowDestination -Label "Sprint Loops workflow destination"
    Assert-SafePathChain -LiteralPath $skillDestination -Label "Sprint Loops skill destination"
    New-Item -ItemType Directory -Force -Path $workflowDirectory | Out-Null
    New-Item -ItemType Directory -Force -Path $skillsDirectory | Out-Null
    Assert-SafePathChain -LiteralPath $workflowDirectory -Label "Antigravity workflow directory"
    Assert-SafePathChain -LiteralPath $skillsDirectory -Label "Antigravity skills directory"
    Assert-SafePathChain -LiteralPath $workflowDestination -Label "Sprint Loops workflow destination"
    Assert-SafePathChain -LiteralPath $skillDestination -Label "Sprint Loops skill destination"

    if (Test-Path -LiteralPath $skillDestination) {
        Move-Item -LiteralPath $skillDestination -Destination $backupSkill
        $skillBackedUp = $true
    }
    if (Test-Path -LiteralPath $workflowDestination) {
        Move-Item -LiteralPath $workflowDestination -Destination $backupWorkflow
        $workflowBackedUp = $true
    }

    Move-Item -LiteralPath $stagedSkill -Destination $skillDestination
    $skillActivated = $true
    Move-Item -LiteralPath $stagedWorkflow -Destination $workflowDestination
    $workflowActivated = $true

    Write-Host "Installed Sprint Loops workflow: $workflowDestination"
    Write-Host "Installed Sprint Loops runtime skill: $skillDestination"
    Write-Host "Installation complete. Use /sprint-loops in Antigravity."
}
catch {
    $installError = $_
    $rollbackErrors = [System.Collections.Generic.List[string]]::new()

    if ($workflowActivated -and (Test-Path -LiteralPath $workflowDestination)) {
        try {
            Remove-Item -Force -LiteralPath $workflowDestination
        }
        catch {
            $rollbackErrors.Add("could not remove newly installed workflow: $($_.Exception.Message)")
        }
    }
    if ($workflowBackedUp -and (Test-Path -LiteralPath $backupWorkflow)) {
        try {
            if (Test-Path -LiteralPath $workflowDestination) {
                throw "destination is occupied"
            }
            Move-Item -LiteralPath $backupWorkflow -Destination $workflowDestination
        }
        catch {
            $rollbackErrors.Add("could not restore prior workflow: $($_.Exception.Message)")
        }
    }

    if ($skillActivated -and (Test-Path -LiteralPath $skillDestination)) {
        try {
            Remove-Item -Recurse -Force -LiteralPath $skillDestination
        }
        catch {
            $rollbackErrors.Add("could not remove newly installed skill: $($_.Exception.Message)")
        }
    }
    if ($skillBackedUp -and (Test-Path -LiteralPath $backupSkill)) {
        try {
            if (Test-Path -LiteralPath $skillDestination) {
                throw "destination is occupied"
            }
            Move-Item -LiteralPath $backupSkill -Destination $skillDestination
        }
        catch {
            $rollbackErrors.Add("could not restore prior skill: $($_.Exception.Message)")
        }
    }

    if ($rollbackErrors.Count -gt 0) {
        $preserveTransaction = $true
        $recoveryMarker = Join-Path -Path $lockPath -ChildPath "RECOVERY.txt"
        try {
            [System.IO.File]::WriteAllLines(
                $recoveryMarker,
                [string[]]@(
                    "Sprint Loops installer recovery required.",
                    "Transaction: $transactionPath"
                )
            )
        }
        catch {
            $rollbackErrors.Add("could not write recovery marker: $($_.Exception.Message)")
        }
        $rollbackSummary = $rollbackErrors -join "; "
        throw "Antigravity installation failed: $($installError.Exception.Message). Rollback was incomplete; recovery data remains at '$transactionPath': $rollbackSummary"
    }

    throw $installError
}
finally {
    if ($transactionCreated -and -not $preserveTransaction -and (Test-Path -LiteralPath $transactionPath)) {
        try {
            Remove-Item -Recurse -Force -LiteralPath $transactionPath
        }
        catch {
            Write-Warning "Could not remove installation staging directory '$transactionPath': $($_.Exception.Message)"
        }
    }

    if ($lockAcquired -and -not $preserveTransaction -and (Test-Path -LiteralPath $lockPath)) {
        try {
            Remove-Item -Recurse -Force -LiteralPath $lockPath
        }
        catch {
            Write-Warning "Could not remove installation lock '$lockPath': $($_.Exception.Message)"
        }
    }
    elseif ($lockAcquired -and $preserveTransaction) {
        Write-Warning "Recovery lock retained at '$lockPath'; inspect RECOVERY.txt before retrying."
    }
}
