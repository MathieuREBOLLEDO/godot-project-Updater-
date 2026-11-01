# Finding git.exe and running it without freezing the window.

function Find-Git {
    $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # Fork ships its own git: newest version folder first.
    $fork = Join-Path $env:LOCALAPPDATA 'Fork\gitInstance'
    if (Test-Path $fork) {
        $byVersion = { try { [version]$_.Name } catch { [version]'0.0' } }
        foreach ($dir in Get-ChildItem $fork -Directory | Sort-Object $byVersion -Descending) {
            $exe = Join-Path $dir.FullName 'cmd\git.exe'
            if (Test-Path $exe) { return $exe }
        }
    }
    $known = @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
    )
    foreach ($exe in $known) { if (Test-Path $exe) { return $exe } }
    return $null
}

function Format-Arg([string]$a) {
    if ($a -eq '' -or $a -match '[\s"]') { return '"' + ($a -replace '"', '\"') + '"' }
    return $a
}

# Runs git in the project folder. -Quiet: query only, nothing logged.
# Sign-in is left to Git Credential Manager (its own window), never a prompt.
function Invoke-Git([string[]]$GitArgs, [switch]$Quiet) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $script:Git
    $psi.Arguments = ($GitArgs | ForEach-Object { Format-Arg $_ }) -join ' '
    $psi.WorkingDirectory = $script:Root
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [Text.Encoding]::UTF8
    $psi.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'

    $p = [Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEndAsync()
    $err = $p.StandardError.ReadToEndAsync()
    while (-not $p.HasExited) {
        if ($script:Pump) { & $script:Pump }
        Start-Sleep -Milliseconds 30
    }
    $p.WaitForExit()
    $result = [pscustomobject]@{ Code = $p.ExitCode; Out = $out.Result.TrimEnd(); Err = $err.Result.TrimEnd() }

    if (-not $Quiet) {
        foreach ($text in @($result.Err, $result.Out)) {
            foreach ($line in $text -split '\r?\n') {
                $line = ($line -split '\r')[-1]
                if ($line) { & $script:Log 'raw' "  $line" }
            }
        }
    }
    return $result
}

function Get-Lines([string]$text) {
    if (-not $text) { return @() }
    return @($text -split '\r?\n' | Where-Object { $_ })
}
