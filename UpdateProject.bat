@echo off
rem Double-click: opens the Project Updater window for this folder.
rem Add "cli" as argument to run without the window (log in the console).
if /i "%~1"=="cli" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\updater\updater.ps1" -Root "%~dp0." -NoWindow
  pause
) else (
  start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0tools\updater\updater.ps1" -Root "%~dp0."
)
