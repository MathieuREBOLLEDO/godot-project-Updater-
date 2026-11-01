# Copies the Project Updater into one or more project folders:
#   powershell -ExecutionPolicy Bypass -File install.ps1 G:\Projects\Godot\BatEmUp [...]
# Updates the scripts, keeps the project's updater.cfg, fills its remote URL
# from the project's origin when there is one.
param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Projects)

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'tools\updater'

foreach ($project in $Projects) {
    $project = (Resolve-Path $project).Path
    $dest = Join-Path $project 'tools\updater'
    New-Item -ItemType Directory $dest -Force | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'UpdateProject.bat') $project -Force
    Copy-Item (Join-Path $src '*.ps1') $dest -Force
    Copy-Item (Join-Path $src '.gdignore') $dest -Force
    # version.cfg: same source as the master, commit = the master's HEAD.
    $commit = & powershell -NoProfile -Command ". '$src\git_run.ps1'; `$script:Git = Find-Git; & `$script:Git -C '$PSScriptRoot' rev-parse HEAD" 2>$null
    $source = (Select-String (Join-Path $src 'version.cfg') -Pattern '^source=(.*)$').Matches[0].Groups[1].Value
    [IO.File]::WriteAllLines((Join-Path $dest 'version.cfg'), @(
            '; Project Updater version. source: repository the tool updates itself from.',
            '; commit: installed version (written by the update, leave it).',
            "source=$source", "commit=$commit"))

    $cfg = Join-Path $dest 'updater.cfg'
    if (-not (Test-Path $cfg)) {
        $remote = ''
        if (Test-Path (Join-Path $project '.git')) {
            $remote = & powershell -NoProfile -Command ". '$src\git_run.ps1'; `$script:Git = Find-Git; & `$script:Git -C '$project' remote get-url origin" 2>$null
        }
        $lines = @(
            '; Project Updater settings (UpdateProject.bat). Commit this file.',
            '; remote_url: git address the project is cloned from.',
            '; language: interface language (en, fr).',
            "remote_url=$remote",
            'language=en'
        )
        [IO.File]::WriteAllLines($cfg, $lines)
    }
    Write-Host "Installed in $project" -ForegroundColor Green
}
