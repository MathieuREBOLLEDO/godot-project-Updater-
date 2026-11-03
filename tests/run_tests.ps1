# Tests de Project Updater, sans réseau ni fenêtre : textes, réglages,
# version, et la mise à jour git sur des dépôts temporaires (un dépôt
# « distant » local). Le git global de l'utilisateur n'est pas touché
# (GIT_CONFIG_GLOBAL temporaire) ; updater.cfg et version.cfg de l'outil non
# plus (chemins redirigés). Sortie 0 si tout passe.
#   powershell -File tests\run_tests.ps1 [-Keep]
param([switch]$Keep)

# Pas d'ErrorActionPreference Stop : git écrit ses messages sur stderr, ce
# qui arrêterait le script ; G() vérifie le code de sortie à la place.
$tool = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\updater'
$temp = Join-Path $env:TEMP ("project_updater_test_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $temp | Out-Null
$failures = New-Object System.Collections.Generic.List[string]

function Check([bool]$ok, [string]$label) {
	if ($ok) { Write-Host "   ok   $label" } else { Write-Host "   FAIL $label"; $failures.Add($label) }
}

# Fonctions de l'outil, dans l'ordre de updater.ps1 (sans la fenêtre).
foreach ($file in 'strings', 'config', 'git_run', 'git_steps', 'self_update') { . (Join-Path $tool "$file.ps1") }
$script:ConfigPath = Join-Path $temp 'updater.cfg'
$script:VersionPath = Join-Path $temp 'version.cfg'
$script:Lang = 'en'
$script:Pump = $null
$script:Logged = New-Object System.Collections.Generic.List[string]
$script:Log = { param($kind, $text) $script:Logged.Add("$kind|$text") }
$script:Git = Find-Git

# Git isolé : identité de test, pas de réglages système ni de l'utilisateur.
$env:GIT_CONFIG_GLOBAL = Join-Path $temp 'gitconfig'
$env:GIT_CONFIG_NOSYSTEM = '1'
[IO.File]::WriteAllLines($env:GIT_CONFIG_GLOBAL, @('[user]', '  name = Updater Test', '  email = test@example.invalid', '[init]', '  defaultBranch = main'))

# git dans un dossier (hors de l'outil, pour préparer les dépôts).
function G([string]$dir) {
	$output = & $script:Git -C $dir @args 2>&1
	if ($LASTEXITCODE -ne 0) { throw "git $args : $output" }
	return $output
}

function Commit([string]$dir, [string]$file, [string]$text) {
	[IO.File]::WriteAllText((Join-Path $dir $file), $text)
	G $dir add $file | Out-Null
	G $dir commit -q -m "edit $file" | Out-Null
}

function Run-Update([string]$root, [string]$remote = '') {
	$script:Root = $root
	$script:Config = @{ remote_url = $remote; language = 'en'; auto_update = 'false' }
	$script:Logged.Clear()
	return Update-Project $remote
}

try {
	Write-Host "-- texts"
	Check ((T 'title') -eq 'Project Updater') "English text"
	Check ((T 'state_repo' 'main') -like '*main*') "text with a value"
	$script:Lang = 'fr'
	Check ($null -ne (T 'title')) "French table answers"
	$script:Strings.en['test_only_english'] = 'Only English'
	Check ((T 'test_only_english') -eq 'Only English') "missing French text falls back to English"
	$script:Strings.en.Remove('test_only_english')
	$script:Lang = 'en'

	Write-Host "`n-- settings and version"
	$cfg = Read-UpdaterConfig
	Check ($cfg.language -eq 'en' -and $cfg.auto_update -eq 'true' -and $cfg.remote_url -eq '') "defaults without file"
	$script:Config = @{ remote_url = 'https://example.invalid/game.git'; language = 'fr'; auto_update = 'false' }
	Save-UpdaterConfig
	$cfg = Read-UpdaterConfig
	Check ($cfg.remote_url -eq 'https://example.invalid/game.git' -and $cfg.language -eq 'fr' -and $cfg.auto_update -eq 'false') "settings round trip"
	[IO.File]::WriteAllLines($script:ConfigPath, @('language=klingon'))
	Check ((Read-UpdaterConfig).language -eq 'en') "unknown language falls back to en"
	Save-ToolVersion @{ source = 'https://example.invalid/tool.git'; commit = 'abc1234' }
	$v = Read-ToolVersion
	Check ($v.source -eq 'https://example.invalid/tool.git' -and $v.commit -eq 'abc1234') "version round trip"

	Write-Host "`n-- git arguments"
	Check ((Format-Arg 'fetch') -eq 'fetch') "plain argument"
	Check ((Format-Arg 'a b') -eq '"a b"') "spaces quoted"
	Check ((Format-Arg '') -eq '""') "empty quoted"
	Check ((Format-Arg 'x"y') -eq '"x\"y"') "quote escaped"
	Check ((Get-Lines "a`n`nb`r`n").Count -eq 2) "Get-Lines drops empty lines"
	Check ($null -ne $script:Git) "git found"

	Write-Host "`n-- update an existing clone"
	$remote = Join-Path $temp 'remote.git'
	$author = Join-Path $temp 'author'
	$project = Join-Path $temp 'project'
	& $script:Git init -q --bare $remote
	& $script:Git clone -q $remote $author 2>&1 | Out-Null
	Commit $author 'readme.txt' 'v1'
	G $author push -q origin main | Out-Null
	& $script:Git clone -q $remote $project 2>&1 | Out-Null
	Commit $author 'readme.txt' 'v2'
	G $author push -q origin main | Out-Null
	G $author checkout -q -b feature | Out-Null
	Commit $author 'feature.txt' 'f'
	G $author push -q origin feature | Out-Null
	G $author checkout -q main | Out-Null

	[IO.File]::WriteAllText((Join-Path $project 'notes.txt'), 'local work')
	Check (Run-Update $project) "update succeeds"
	Check ((G $project rev-parse main) -eq (G $author rev-parse main)) "current branch fast-forwarded"
	Check ([IO.File]::ReadAllText((Join-Path $project 'readme.txt')) -eq 'v2') "new file content"
	Check ((G $project branch --list feature) -match 'feature') "missing branch created"
	Check ((G $project rev-parse --abbrev-ref 'feature@{u}') -eq 'origin/feature') "it tracks origin"
	Check ([IO.File]::ReadAllText((Join-Path $project 'notes.txt')) -eq 'local work') "untracked local work kept"
	Check ((Read-UpdaterConfig).remote_url -eq $remote) "remote saved in updater.cfg"

	Write-Host "`n-- diverged branch is left alone"
	Commit $project 'readme.txt' 'local change'
	$local = G $project rev-parse main
	Commit $author 'readme.txt' 'v3'
	G $author push -q origin main | Out-Null
	Check (Run-Update $project) "update runs"
	Check ((G $project rev-parse main) -eq $local) "local commit not moved"
	Check (($script:Logged | Where-Object { $_ -like 'bad|*' }).Count -gt 0) "divergence reported"

	Write-Host "`n-- other branch fast-forwarded"
	G $author checkout -q feature | Out-Null
	Commit $author 'feature.txt' 'f2'
	G $author push -q origin feature | Out-Null
	G $author checkout -q main | Out-Null
	Run-Update $project | Out-Null
	Check ((G $project rev-parse feature) -eq (G $author rev-parse feature)) "not checked out branch moved forward"

	Write-Host "`n-- folder without git (downloaded ZIP)"
	$zip = Join-Path $temp 'zip'
	New-Item -ItemType Directory -Path $zip | Out-Null
	[IO.File]::WriteAllText((Join-Path $zip 'readme.txt'), 'edited in the zip')
	Check (Run-Update $zip $remote) "linked to the remote"
	Check (Test-Path (Join-Path $zip '.git')) "repository created"
	Check ([IO.File]::ReadAllText((Join-Path $zip 'readme.txt')) -eq 'edited in the zip') "existing file kept"
	Check ((G $zip rev-parse main) -eq (G $author rev-parse main)) "on the remote main"

	Write-Host "`n-- no remote"
	$empty = Join-Path $temp 'empty'
	New-Item -ItemType Directory -Path $empty | Out-Null
	Check (-not (Run-Update $empty '')) "fails without a remote"
	Check (-not (Test-Path (Join-Path $empty '.git'))) "nothing created"
}
catch {
	$failures.Add("exception: $_")
	Write-Host "   FAIL exception: $_"
}
finally {
	Remove-Item Env:GIT_CONFIG_GLOBAL, Env:GIT_CONFIG_NOSYSTEM -ErrorAction SilentlyContinue
	if (-not $Keep) { Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue }
}

Write-Host ""
if ($failures.Count -eq 0) { Write-Host "== all passed"; exit 0 }
Write-Host "== $($failures.Count) failed"
$failures | ForEach-Object { Write-Host "   FAILED $_" }
exit 1
