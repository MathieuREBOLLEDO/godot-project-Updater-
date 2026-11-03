Project Updater
===============

Double-click UpdateProject.bat at the root of a project: a window brings the
folder up to date with its GitHub repository. Works without Python or
anything to install (PowerShell + Windows Forms). git is looked up in the
PATH, then in Fork, then in Git for Windows.

What it does
- Downloaded ZIP or empty folder: git init, links it to remote_url
  (tools/updater/updater.cfg), keeps the files present, puts back the
  missing ones.
- Clone: fetch of all branches, fast-forward of the current branch.
- Creates a local branch for each remote branch, fast-forwards the others.
- Installs the add-ons (submodules) that are missing.
- Never discards local work: a branch that diverged, a local change in the
  way or a submodule on a branch with its own commits are left as is and
  shown in the log.
- GitHub sign-in: Git Credential Manager (browser window the first time).
  Name / email fields = git config --global.

Without a window: UpdateProject.bat cli

Self-update
- At launch, the tool compares its installed commit (tools/updater/version.cfg,
  commit=) with the HEAD of its own repository (source=). If it changed, it
  copies the new scripts and UpdateProject.bat, then relaunches itself.
- To publish a new version: edit this folder, commit, push. Every project
  picks it up the next time its updater is launched.
- Offline: the installed version runs. auto_update=false in updater.cfg
  keeps a project on its current version.

Install in a project (master copy = this folder):
  powershell -ExecutionPolicy Bypass -File install.ps1 <project folder> [...]
Then commit UpdateProject.bat and tools/updater/ with the project.

Files (tools/updater/)
  updater.ps1    entry point (window or -NoWindow)
  git_run.ps1    finding and running git
  git_steps.ps1  the update steps
  strings.ps1    interface texts (en, fr), add a language here
  theme.ps1      colors, fonts, sizes (design_tokens.cfg [colors] overrides)
  widgets.ps1    themed controls, background
  window.ps1     the window
  config.ps1     updater.cfg (remote_url, language)

Tests
-----
powershell -File tests\run_tests.ps1   (sortie 0 si tout passe)
Sans reseau ni fenetre : textes, updater.cfg, version.cfg, arguments git, et
la mise a jour sur des depots temporaires (clone existant, branche divergee,
autre branche, dossier sans git, sans remote). Le git global et les fichiers
de l'outil ne sont pas touches.
