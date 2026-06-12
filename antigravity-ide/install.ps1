<#
.SYNOPSIS
Installs the Sprint Loops skill for Antigravity IDE.

.DESCRIPTION
This script copies the global workflow definition to the Antigravity global_workflows directory.
#>

$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "global_workflows\sprint-loops.md"
$destinationDir = Join-Path -Path $HOME -ChildPath ".gemini\config\global_workflows"
$destinationPath = Join-Path -Path $destinationDir -ChildPath "sprint-loops.md"

if (-not (Test-Path -Path $destinationDir)) {
    Write-Host "Creating Antigravity global_workflows directory..."
    New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
}

Write-Host "Installing Sprint Loops global workflow..."
Copy-Item -Force -Path $sourcePath -Destination $destinationPath

Write-Host "Installation complete! You can now use /sprint-loops in Antigravity."
