@echo off
setlocal EnableExtensions

:: One-step engine build for Windows (MinGW-w64). Produces engine\dist\win11\ with exe + SDL2.dll.
:: Requires: MSYS2 or standalone MinGW-w64 with mingw32-make and gcc on PATH.
::
:: For Visual Studio instead, open "x64 Native Tools Command Prompt" and run:
::   build.bat --preset win11 --package

cd /d "%~dp0"

where mingw32-make >nul 2>&1
if errorlevel 1 (
  echo.
  echo ERROR: mingw32-make was not found on PATH.
  echo.
  echo Quick setup (MSYS2^):
  echo   1. Install MSYS2 from https://www.msys2.org/
  echo   2. In "MSYS2 UCRT64" or "MINGW64" terminal, run:
  echo        pacman -S --needed mingw-w64-ucrt-x86_64-toolchain
  echo   3. Add the bin folder to your PATH, e.g.:
  echo        C:\msys64\ucrt64\bin
  echo   Then run this script again from cmd or Explorer.
  echo.
  exit /b 1
)

echo Building engine (win11, MinGW, packaged^)...
call build.bat --preset win11 --mingw --package %*
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo Done. Run the game: run_game.cmd
echo Packaged files: engine\dist\win11\
exit /b 0
