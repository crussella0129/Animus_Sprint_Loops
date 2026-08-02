param(
    [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "antigravity-adapter-contract: $Message"
    }
}

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Expected,
        [string]$Label
    )

    Assert-True -Condition $Text.Contains($Expected) -Message "$Label lacks required text: $Expected"
}

function Assert-NotMatch {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Label
    )

    Assert-True -Condition (-not [regex]::IsMatch($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)) -Message "$Label contains forbidden pattern: $Pattern"
}

function Get-MappingRow {
    param(
        [string]$Text,
        [string]$Artifact
    )

    $marker = "| " + [char]96 + $Artifact + [char]96 + " |"
    $rows = @(
        [regex]::Split($Text, "\r?\n") |
            Where-Object { $_.StartsWith($marker, [StringComparison]::Ordinal) }
    )
    Assert-True -Condition ($rows.Count -eq 1) -Message "expected one mapping row for $Artifact, found $($rows.Count)"
    return $rows[0]
}

function Get-FileMap {
    param(
        [string]$Root
    )

    $resolvedRoot = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $map = @{}
    foreach ($file in Get-ChildItem -Force -File -Recurse -LiteralPath $resolvedRoot) {
        $relative = $file.FullName.Substring($resolvedRoot.Length).TrimStart(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        )
        $map[$relative] = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    }
    return $map
}

function Assert-SameFileMap {
    param(
        [string]$ExpectedRoot,
        [string]$ActualRoot,
        [string]$Label
    )

    $expected = Get-FileMap -Root $ExpectedRoot
    $actual = Get-FileMap -Root $ActualRoot
    Assert-True -Condition ($expected.Count -eq $actual.Count) -Message "$Label file count differs"
    foreach ($relative in $expected.Keys) {
        Assert-True -Condition $actual.ContainsKey($relative) -Message "$Label lacks $relative"
        Assert-True -Condition ($actual[$relative] -eq $expected[$relative]) -Message "$Label differs at $relative"
    }
}

$antigravityRoot = Join-Path -Path $RepositoryRoot -ChildPath "antigravity-ide"
$workflowPath = Join-Path -Path $antigravityRoot -ChildPath "global_workflows\sprint-loops.md"
$runtimeSkillPath = Join-Path -Path $antigravityRoot -ChildPath "skills\sprint-loop"
$runtimeEntryPath = Join-Path -Path $runtimeSkillPath -ChildPath "SKILL.md"
$installPath = Join-Path -Path $antigravityRoot -ChildPath "install.ps1"

$workflow = [IO.File]::ReadAllText($workflowPath)
$runtimeEntry = [IO.File]::ReadAllText($runtimeEntryPath)

# test_antigravity_maps_native_artifacts_to_book
Assert-Contains -Text $workflow -Expected "schema-version: 2" -Label "workflow"
Assert-Contains -Text $workflow -Expected "non-authoritative" -Label "workflow"
$implementationRow = Get-MappingRow -Text $workflow -Artifact "implementation_plan.md"
$taskRow = Get-MappingRow -Text $workflow -Artifact "task.md"
$walkthroughRow = Get-MappingRow -Text $workflow -Artifact "walkthrough.md"

Assert-Contains -Text $implementationRow -Expected "unrealized intent and planning" -Label "implementation plan mapping"
Assert-Contains -Text $implementationRow -Expected "docs/intents/" -Label "implementation plan mapping"
Assert-Contains -Text $implementationRow -Expected "docs/sprints/sN/sprint-plans/" -Label "implementation plan mapping"
Assert-Contains -Text $taskRow -Expected "work state" -Label "task mapping"
Assert-Contains -Text $taskRow -Expected "docs/work/tasks.md" -Label "task mapping"
Assert-Contains -Text $taskRow -Expected "docs/work/completed-tasks.md" -Label "task mapping"
Assert-Contains -Text $walkthroughRow -Expected "realization evidence" -Label "walkthrough mapping"
Assert-Contains -Text $walkthroughRow -Expected "Completion evidence plus at least one Code, Test, or Documentation evidence link" -Label "walkthrough mapping"
Assert-Contains -Text $walkthroughRow -Expected "walkthrough alone never realizes intent" -Label "walkthrough mapping"
Assert-Contains -Text $workflow -Expected "Another harness must be able to resume from the Book alone" -Label "cross-harness contract"

$planSectionMatch = [regex]::Match(
    $workflow,
    "(?ms)^### Plan\s+(?<body>.*?)(?=^### Build\s)")
Assert-True -Condition $planSectionMatch.Success -Message "workflow lacks one Plan section"
$planSection = $planSectionMatch.Groups["body"].Value
Assert-Contains -Text $planSection -Expected "from the research report, linked intent" -Label "Plan projection direction"
Assert-Contains -Text $planSection -Expected "does not become an upstream" -Label "Plan projection direction"
foreach ($transitionText in @("proposed", "deferred", "planned", "Work evidence", "actual transition")) {
    Assert-Contains -Text $planSection -Expected $transitionText -Label "Plan Book transition"
}

foreach ($helper in @(
    "current-phase.sh",
    "finalize-plan.sh",
    "commit-task.sh",
    "check-book.sh",
    "close-sprint.sh"
)) {
    Assert-Contains -Text $workflow -Expected $helper -Label "workflow helper routing"
}

Assert-Contains -Text $workflow -Expected "Always Proceed" -Label "Antigravity authority"
Assert-Contains -Text $workflow -Expected "auto-accept" -Label "Antigravity authority"
Assert-Contains -Text $workflow -Expected "enlarge authority" -Label "Antigravity authority"

$remoteRule = "Push, merge, release, force-push, delete, and material scope expansion require an explicit request or a declared preauthorized-remote profile."
$remoteCount = [regex]::Matches(
    $workflow + [Environment]::NewLine + $runtimeEntry,
    [regex]::Escape($remoteRule)
).Count
Assert-True -Condition ($remoteCount -eq 1) -Message "expected one exact remote authority rule, found $remoteCount"

Assert-NotMatch -Text $workflow -Pattern "agent-tasks/|(?<!docs/)sprints/|decisions\.md|Finalized - DO NOT EDIT|antigravity-ide/skills|gh\s+pr|proceeds autonomously" -Label "workflow"

# Parse before executing, then prove that the official workflow and skill
# destinations update together from an arbitrary source checkout.
$tokens = $null
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    $installPath,
    [ref]$tokens,
    [ref]$parseErrors
)
Assert-True -Condition ($parseErrors.Count -eq 0) -Message "install.ps1 has parser errors: $($parseErrors -join '; ')"

$testRoot = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ("sprint-loops-antigravity-" + [Guid]::NewGuid().ToString("N"))
$configRoot = Join-Path -Path $testRoot -ChildPath "config root with spaces"
$installedWorkflow = Join-Path -Path $configRoot -ChildPath "global_workflows\sprint-loops.md"
$installedSkill = Join-Path -Path $configRoot -ChildPath "skills\sprint-loop"
$lockPath = Join-Path -Path $configRoot -ChildPath ".sprint-loops-install.lock"

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null

    $physicalRoot = Join-Path -Path $testRoot -ChildPath "physical config parent"
    $aliasPath = Join-Path -Path $testRoot -ChildPath "aliased config parent"
    New-Item -ItemType Directory -Path $physicalRoot | Out-Null
    New-Item -ItemType Junction -Path $aliasPath -Target $physicalRoot | Out-Null
    $aliasConfigRoot = Join-Path -Path $aliasPath -ChildPath "config"
    $aliasRefused = $false
    try {
        & $installPath -ConfigRoot $aliasConfigRoot | Out-Null
    }
    catch {
        $aliasRefused = $true
    }
    Assert-True -Condition $aliasRefused -Message "installer accepted an ancestor junction"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $physicalRoot "config"))) -Message "alias refusal wrote through the junction before validation"
    Remove-Item -Force -LiteralPath $aliasPath

    & $installPath -ConfigRoot $configRoot | Out-Null

    Assert-True -Condition (Test-Path -LiteralPath $installedWorkflow -PathType Leaf) -Message "installer omitted the global workflow"
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $installedSkill "SKILL.md") -PathType Leaf) -Message "installer omitted the runtime SKILL.md"
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $installedSkill "scripts\current-phase.sh") -PathType Leaf) -Message "installer omitted current-phase.sh"
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $installedSkill "schemas\intent.md") -PathType Leaf) -Message "installer omitted intent.md"
    Assert-SameFileMap -ExpectedRoot $runtimeSkillPath -ActualRoot $installedSkill -Label "initial runtime skill install"
    Assert-True -Condition ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedWorkflow).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $workflowPath).Hash) -Message "installed workflow differs from its source"

    Set-Content -LiteralPath (Join-Path $installedSkill "stale.txt") -Value "stale"
    Set-Content -LiteralPath $installedWorkflow -Value "stale"
    & $installPath -ConfigRoot $configRoot | Out-Null

    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $installedSkill "stale.txt"))) -Message "reinstall retained a stale runtime file"
    Assert-SameFileMap -ExpectedRoot $runtimeSkillPath -ActualRoot $installedSkill -Label "updated runtime skill install"
    Assert-True -Condition ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedWorkflow).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $workflowPath).Hash) -Message "reinstalled workflow differs from its source"

    New-Item -ItemType Directory -Path $lockPath | Out-Null
    Set-Content -LiteralPath (Join-Path $installedSkill "preserve.txt") -Value "preserve"
    $workflowHashBeforeLock = (Get-FileHash -Algorithm SHA256 -LiteralPath $installedWorkflow).Hash
    $lockRefused = $false
    try {
        & $installPath -ConfigRoot $configRoot | Out-Null
    }
    catch {
        $lockRefused = $true
    }
    Assert-True -Condition $lockRefused -Message "installer ignored an existing transaction/recovery lock"
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $installedSkill "preserve.txt") -PathType Leaf) -Message "lock refusal mutated the prior skill"
    Assert-True -Condition ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedWorkflow).Hash -eq $workflowHashBeforeLock) -Message "lock refusal mutated the prior workflow"
    Remove-Item -Recurse -Force -LiteralPath $lockPath

    $brokenBundle = Join-Path -Path $testRoot -ChildPath "broken bundle"
    New-Item -ItemType Directory -Path $brokenBundle | Out-Null
    $brokenInstaller = Join-Path -Path $brokenBundle -ChildPath "install.ps1"
    Copy-Item -LiteralPath $installPath -Destination $brokenInstaller
    $missingSourceRefused = $false
    try {
        & $brokenInstaller -ConfigRoot $configRoot | Out-Null
    }
    catch {
        $missingSourceRefused = $true
    }
    Assert-True -Condition $missingSourceRefused -Message "installer with missing source bundle succeeded"
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $installedSkill "preserve.txt") -PathType Leaf) -Message "missing-source failure mutated the prior skill"
    Assert-True -Condition ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedWorkflow).Hash -eq $workflowHashBeforeLock) -Message "missing-source failure mutated the prior workflow"

    Set-Content -LiteralPath $installedWorkflow -Value "known-good-workflow"
    Set-Content -LiteralPath (Join-Path $installedSkill "rollback-sentinel.txt") -Value "known-good-skill"
    $env:T116_FAIL_WORKFLOW_DESTINATION = $installedWorkflow
    $env:T116_WORKFLOW_FAILURE_INJECTED = "0"
    function global:Move-Item {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$LiteralPath,

            [Parameter(Mandatory = $true)]
            [string]$Destination
        )

        $sourceParent = Split-Path -Parent $LiteralPath
        if (
            $env:T116_WORKFLOW_FAILURE_INJECTED -eq "0" -and
            $Destination -eq $env:T116_FAIL_WORKFLOW_DESTINATION -and
            (Split-Path -Leaf $LiteralPath) -eq "sprint-loops.md" -and
            (Split-Path -Leaf $sourceParent) -like ".sprint-loops-install-*"
        ) {
            $env:T116_WORKFLOW_FAILURE_INJECTED = "1"
            throw "injected workflow activation failure"
        }

        Microsoft.PowerShell.Management\Move-Item @PSBoundParameters
    }

    $activationFailureObserved = $false
    try {
        & $installPath -ConfigRoot $configRoot | Out-Null
    }
    catch {
        $activationFailureObserved = $true
    }
    finally {
        Remove-Item -Force Function:\global:Move-Item
        Remove-Item Env:\T116_FAIL_WORKFLOW_DESTINATION
        Remove-Item Env:\T116_WORKFLOW_FAILURE_INJECTED
    }
    Assert-True -Condition $activationFailureObserved -Message "injected second-target activation failure reported success"
    Assert-True -Condition ((Get-Content -Raw -LiteralPath $installedWorkflow).Trim() -eq "known-good-workflow") -Message "activation rollback did not restore the prior workflow"
    Assert-True -Condition ((Get-Content -Raw -LiteralPath (Join-Path $installedSkill "rollback-sentinel.txt")).Trim() -eq "known-good-skill") -Message "activation rollback did not restore the prior skill"
    Assert-True -Condition (-not (Test-Path -LiteralPath $lockPath)) -Message "clean activation rollback retained its lock"

    & $installPath -ConfigRoot $configRoot | Out-Null
    Assert-SameFileMap -ExpectedRoot $runtimeSkillPath -ActualRoot $installedSkill -Label "post-rollback runtime skill install"
    Assert-True -Condition ((Get-FileHash -Algorithm SHA256 -LiteralPath $installedWorkflow).Hash -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $workflowPath).Hash) -Message "post-rollback workflow differs from its source"

    $transactionArtifacts = @(
        Get-ChildItem -Force -LiteralPath $configRoot |
            Where-Object Name -Like ".sprint-loops-install-*"
    )
    Assert-True -Condition ($transactionArtifacts.Count -eq 0) -Message "clean installs left transaction artifacts"
}
finally {
    if (Test-Path -LiteralPath (Join-Path $testRoot "aliased config parent")) {
        Remove-Item -Force -LiteralPath (Join-Path $testRoot "aliased config parent")
    }
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -Recurse -Force -LiteralPath $testRoot
    }
}

Write-Output "antigravity-adapter-contract: test_antigravity_maps_native_artifacts_to_book passed"
