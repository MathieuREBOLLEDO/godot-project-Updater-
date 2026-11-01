# Project Updater: brings a Godot project folder up to date with its git
# remote (init if needed, all branches, add-on submodules).
# Launched by UpdateProject.bat at the project root.
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$NoWindow,
    # Set by the relaunch after a self-update: skips the check, shown in the log.
    [string]$UpdatedTo = ''
)

$ErrorActionPreference = 'Stop'
$script:Root = (Resolve-Path $Root).Path.TrimEnd('\')
$script:Here = $PSScriptRoot

. (Join-Path $Here 'strings.ps1')
. (Join-Path $Here 'config.ps1')
. (Join-Path $Here 'git_run.ps1')
. (Join-Path $Here 'git_steps.ps1')
. (Join-Path $Here 'self_update.ps1')

$script:Config = Read-UpdaterConfig
$script:Lang = $script:Config.language
$script:Git = Find-Git
$script:UpdatedTo = $UpdatedTo

# A newer tool replaces these scripts, then runs in a fresh process.
if ($script:Git -and -not $UpdatedTo -and $script:Config.auto_update -ne 'false') {
    $new = Update-Tool
    if ($new) {
        $relaunch = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath,
            '-Root', $script:Root, '-UpdatedTo', $new)
        if ($NoWindow) {
            & powershell @relaunch -NoWindow
            exit $LASTEXITCODE
        }
        # PowerShell's own -WindowStyle hides only its console; Start-Process's
        # would hide the form too.
        Start-Process powershell -ArgumentList (@('-WindowStyle', 'Hidden') + $relaunch | ForEach-Object { Format-Arg $_ })
        exit 0
    }
}

if ($NoWindow) {
    $script:Log = {
        param($kind, $text)
        $colors = @{ step = 'Cyan'; good = 'Green'; bad = 'Red'; info = 'Gray'; raw = 'DarkGray' }
        Write-Host $text -ForegroundColor $colors[$kind]
    }
    if (-not $script:Git) { & $script:Log 'bad' (T 'err_no_git'); exit 1 }
    if ($UpdatedTo) { & $script:Log 'good' (T 'msg_tool_updated' $UpdatedTo) }
    $ok = Update-Project (Get-RemoteUrl)
    if ($ok) { exit 0 } else { exit 1 }
}

. (Join-Path $Here 'theme.ps1')
. (Join-Path $Here 'window.ps1')
Show-UpdaterWindow
