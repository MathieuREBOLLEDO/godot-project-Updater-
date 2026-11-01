# The update itself, step by step. Never discards local work: branches only
# fast-forward, and a submodule is moved only if it is missing or detached.

function Test-Repo { Test-Path (Join-Path $script:Root '.git') }

function Get-Origin {
    if (-not (Test-Repo)) { return '' }
    return (Invoke-Git @('remote', 'get-url', 'origin') -Quiet).Out
}

# The remote of an existing repo wins over the saved one.
function Get-RemoteUrl {
    $origin = Get-Origin
    if ($origin) { return $origin }
    return $script:Config.remote_url
}

function Get-CurrentBranch { (Invoke-Git @('symbolic-ref', '--short', '-q', 'HEAD') -Quiet).Out }

function Update-Project([string]$RemoteUrl) {
    if (-not (Test-Repo)) {
        if (-not (Initialize-Repo $RemoteUrl)) { return $false }
    } else {
        & $script:Log 'step' (T 'step_fetch')
        if ((Invoke-Git @('fetch', '--all', '--prune', '--tags')).Code -ne 0) {
            & $script:Log 'bad' (T 'msg_failed' (T 'err_fetch')); return $false
        }
        Update-CurrentBranch
    }
    Add-MissingBranches
    Update-OtherBranches
    Update-Submodules
    Show-Summary
    $script:Config.remote_url = Get-Origin
    Save-UpdaterConfig
    return $true
}

# A downloaded ZIP or an empty folder: link it to the remote, keep its files,
# put back the missing ones.
function Initialize-Repo([string]$RemoteUrl) {
    if (-not $RemoteUrl) { & $script:Log 'bad' (T 'err_no_remote'); return $false }
    & $script:Log 'step' (T 'step_init' $RemoteUrl)
    Invoke-Git @('-c', 'init.defaultBranch=main', 'init', '-q') | Out-Null
    Invoke-Git @('remote', 'add', 'origin', $RemoteUrl) | Out-Null
    & $script:Log 'step' (T 'step_fetch')
    if ((Invoke-Git @('fetch', 'origin', '--prune', '--tags')).Code -ne 0) {
        Remove-Item (Join-Path $script:Root '.git') -Recurse -Force
        & $script:Log 'bad' (T 'msg_failed' (T 'err_fetch')); return $false
    }
    Invoke-Git @('remote', 'set-head', 'origin', '--auto') -Quiet | Out-Null
    $default = (Invoke-Git @('symbolic-ref', '--short', 'refs/remotes/origin/HEAD') -Quiet).Out
    if (-not $default) { $default = 'origin/main' }
    $branch = $default -replace '^origin/', ''

    Invoke-Git @('symbolic-ref', 'HEAD', "refs/heads/$branch") -Quiet | Out-Null
    Invoke-Git @('reset', '-q', '--mixed', $default) | Out-Null
    Invoke-Git @('branch', '-q', "--set-upstream-to=$default", $branch) | Out-Null
    $missing = (Get-Lines (Invoke-Git @('ls-files', '--deleted') -Quiet).Out).Count
    if ($missing) {
        # Writes only files that do not exist yet.
        Invoke-Git @('checkout-index', '-a', '-q') -Quiet | Out-Null
        & $script:Log 'good' (T 'msg_restored' $missing $default)
    }
    & $script:Log 'good' (T 'msg_uptodate' $branch)
    return $true
}

# "ahead behind" of a branch against another.
function Get-Distance([string]$branch, [string]$other) {
    $counts = (Invoke-Git @('rev-list', '--left-right', '--count', "$branch...$other") -Quiet).Out -split '\s+'
    return @([int]$counts[0], [int]$counts[1])
}

function Update-CurrentBranch {
    $cur = Get-CurrentBranch
    if (-not $cur) { & $script:Log 'info' (T 'msg_detached'); return }
    & $script:Log 'step' (T 'step_current' $cur)
    $up = (Invoke-Git @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}') -Quiet).Out
    if (-not $up) {
        if ((Invoke-Git @('show-ref', '--verify', '-q', "refs/remotes/origin/$cur") -Quiet).Code -ne 0) {
            & $script:Log 'info' (T 'msg_no_upstream' $cur); return
        }
        $up = "origin/$cur"
        Invoke-Git @('branch', '-q', "--set-upstream-to=$up", $cur) | Out-Null
    }
    $ahead, $behind = Get-Distance $cur $up
    if ($ahead -and $behind) { & $script:Log 'bad' (T 'msg_diverged' $cur $up); return }
    if ($ahead) { & $script:Log 'info' (T 'msg_ahead' $cur $ahead) }
    if (-not $behind) { if (-not $ahead) { & $script:Log 'good' (T 'msg_uptodate' $cur) }; return }
    # Refuses by itself if a local change would be overwritten.
    if ((Invoke-Git @('merge', '--ff-only', '-q', $up)).Code -eq 0) {
        & $script:Log 'good' (T 'msg_ff' $cur $behind)
    } else {
        & $script:Log 'bad' (T 'msg_ff_blocked' $cur)
    }
}

function Add-MissingBranches {
    & $script:Log 'step' (T 'step_branches')
    $created = 0
    foreach ($ref in Get-Lines (Invoke-Git @('for-each-ref', '--format=%(refname:short)', 'refs/remotes/origin') -Quiet).Out) {
        if ($ref -notmatch '^origin/(.+)$' -or $Matches[1] -eq 'HEAD') { continue }
        $name = $Matches[1]
        if ((Invoke-Git @('show-ref', '--verify', '-q', "refs/heads/$name") -Quiet).Code -eq 0) { continue }
        Invoke-Git @('branch', '-q', '--track', $name, $ref) | Out-Null
        & $script:Log 'good' (T 'msg_branch_created' $name)
        $created++
    }
    if (-not $created) { & $script:Log 'info' (T 'msg_no_new_branch') }
}

# Branches that are not checked out: moved forward only when nothing local
# would be lost.
function Update-OtherBranches {
    & $script:Log 'step' (T 'step_others')
    $cur = Get-CurrentBranch
    $format = '--format=%(refname:short)|%(upstream:short)'
    foreach ($line in Get-Lines (Invoke-Git @('for-each-ref', $format, 'refs/heads') -Quiet).Out) {
        $name, $up = $line -split '\|', 2
        if ($name -eq $cur -or -not $up) { continue }
        if ((Invoke-Git @('rev-parse', '-q', '--verify', $up) -Quiet).Code -ne 0) { continue }
        $ahead, $behind = Get-Distance $name $up
        if (-not $behind) { continue }
        if ($ahead) { & $script:Log 'bad' (T 'msg_diverged' $name $up); continue }
        Invoke-Git @('branch', '-f', $name, $up) -Quiet | Out-Null
        & $script:Log 'good' (T 'msg_ff' $name $behind)
    }
}

function Update-Submodules {
    if (-not (Test-Path (Join-Path $script:Root '.gitmodules'))) { return }
    & $script:Log 'step' (T 'step_submodules')
    Invoke-Git @('submodule', 'sync', '--recursive') -Quiet | Out-Null
    $todo = @()
    foreach ($line in Get-Lines (Invoke-Git @('submodule', 'status') -Quiet).Out) {
        if ($line -notmatch '^([ +\-U])[0-9a-f]+ (\S+)') { continue }
        $state, $path = $Matches[1], $Matches[2]
        if ($state -eq '-') { $todo += $path; continue }
        if ($state -eq ' ') { & $script:Log 'good' (T 'msg_sub_ok' $path); continue }
        $branch = (Invoke-Git @('-C', $path, 'symbolic-ref', '--short', '-q', 'HEAD') -Quiet).Out
        if ($branch) { & $script:Log 'info' (T 'msg_sub_branch' $path $branch) } else { $todo += $path }
    }
    if (-not $todo) { return }
    $result = Invoke-Git (@('submodule', 'update', '--init', '--recursive', '--') + $todo)
    foreach ($path in $todo) {
        if ($result.Code -eq 0) { & $script:Log 'good' (T 'msg_sub_init' $path) }
    }
    if ($result.Code -ne 0) { & $script:Log 'bad' (T 'msg_failed' (T 'err_submodules')) }
}

function Show-Summary {
    $dirty = (Get-Lines (Invoke-Git @('status', '--porcelain', '--ignore-submodules=dirty') -Quiet).Out).Count
    if ($dirty) { & $script:Log 'info' (T 'msg_dirty' $dirty) }
    & $script:Log 'good' (T 'msg_done')
}

function Get-Identity {
    @{
        name  = (Invoke-Git @('config', '--global', 'user.name') -Quiet).Out
        email = (Invoke-Git @('config', '--global', 'user.email') -Quiet).Out
    }
}

function Set-Identity([string]$name, [string]$email) {
    $now = Get-Identity
    if ($name -and $name -ne $now.name) { Invoke-Git @('config', '--global', 'user.name', $name) -Quiet | Out-Null }
    if ($email -and $email -ne $now.email) { Invoke-Git @('config', '--global', 'user.email', $email) -Quiet | Out-Null }
    if (($name -and $name -ne $now.name) -or ($email -and $email -ne $now.email)) {
        & $script:Log 'good' (T 'msg_identity_saved')
    }
}
