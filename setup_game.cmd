@echo off
setlocal EnableExtensions

:: One-click game setup for Operation Deadfall:
:: - Downloads required NZ:P game data and runtime if missing
:: - Sets up engine binaries (and builds if needed)
:: - Compiles Operation Deadfall QuakeC bytecode and deploys to nzp\
:: - Validates everything is ready to run

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup_game.ps1" %*
set "EC=%ERRORLEVEL%"

if "%~1"=="" if not "%EC%"=="0" (
  echo.
  echo Setup encountered an issue. Review the output above.
  pause
)

exit /b %EC%
