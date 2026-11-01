# Self-update: at launch, compares the installed commit of the tool with its
# source repository (version.cfg) and replaces the scripts when it changed.
# Offline or unreachable: the installed version just runs.

$script:VersionPath = Join-Path $PSScriptRoot 'version.cfg'

function Read-ToolVersion {
    $v = @{ source = ''; commit = '' }
    if (Test-Path $script:VersionPath) {
        foreach ($line in [IO.File]::ReadAllLines($script:VersionPath)) {
            if ($line -match '^\s*([a-z_]+)\s*=\s*(.*?)\s*$') { $v[$Matches[1]] = $Matches[2] }
        }
    }
    return $v
}

function Save-ToolVersion($v) {
    $lines = @(
        '; Project Updater version. source: repository the tool updates itself from.',
        '; commit: installed version (written by the update, leave it).',
        "source=$($v.source)",
        "commit=$($v.commit)"
    )
    [IO.File]::WriteAllLines($script:VersionPath, $lines)
}

# Returns the new short commit when the tool was replaced, else ''.
function Update-Tool {
    $v = Read-ToolVersion
    if (-not $v.source) { return '' }
    $remote = Invoke-Git @('ls-remote', $v.source, 'HEAD') -Quiet
    $head = ($remote.Out -split '\s+')[0]
    if ($remote.Code -ne 0 -or -not $head -or $head -eq $v.commit) { return '' }

    $temp = Join-Path $env:TEMP "project_updater_$PID"
    if ((Invoke-Git @('clone', '-q', '--depth', '1', $v.source, $temp) -Quiet).Code -ne 0) { return '' }
    try {
        Copy-Item (Join-Path $temp 'UpdateProject.bat') $script:Root -Force
        Get-ChildItem (Join-Path $temp 'tools\updater') -Force |
            Where-Object { $_.Name -notin @('updater.cfg', 'version.cfg') } |
            Copy-Item -Destination $PSScriptRoot -Force
        $v.commit = $head
        Save-ToolVersion $v
    } finally {
        Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
    return $head.Substring(0, 7)
}
