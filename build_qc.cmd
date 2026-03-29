@echo off
:: Wrapper so you can run QuakeC builds without typing PowerShell flags.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_qc.ps1" %*
exit /b %ERRORLEVEL%
