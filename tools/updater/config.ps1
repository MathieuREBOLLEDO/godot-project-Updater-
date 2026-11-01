# updater.cfg: per-project settings (remote URL, language), key=value lines.
# Commit it with the project so a downloaded ZIP still knows its remote.

$script:ConfigPath = Join-Path $PSScriptRoot 'updater.cfg'

function Read-UpdaterConfig {
    $cfg = @{ remote_url = ''; language = 'en'; auto_update = 'true' }
    if (Test-Path $script:ConfigPath) {
        foreach ($line in [IO.File]::ReadAllLines($script:ConfigPath)) {
            if ($line -match '^\s*([a-z_]+)\s*=\s*(.*?)\s*$') { $cfg[$Matches[1]] = $Matches[2] }
        }
    }
    if (-not $script:Strings.ContainsKey($cfg.language)) { $cfg.language = 'en' }
    return $cfg
}

function Save-UpdaterConfig {
    $lines = @(
        '; Project Updater settings (UpdateProject.bat). Commit this file.',
        '; remote_url: git address the project is cloned from.',
        '; language: interface language (en, fr).',
        '; auto_update: false keeps this version of the tool (no check at launch).',
        "remote_url=$($script:Config.remote_url)",
        "language=$($script:Config.language)",
        "auto_update=$($script:Config.auto_update)"
    )
    [IO.File]::WriteAllLines($script:ConfigPath, $lines)
}
