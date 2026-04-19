@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Launch Operation Deadfall from a repo clone on Windows (like ./run_game.sh on Linux).
:: Put nzp\ inside the repo root or in the parent folder, then double-click or:
::   run_game.cmd
::   run_game.cmd -- +map nzp_asylum

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"

set "USE_DIST="
set "BINARY_OVERRIDE="
set "COLLECT_ENGINE_ARGS=0"
set "ENGINE_ARGS="

:parse_args
if "%~1"=="" goto end_parse
if "!COLLECT_ENGINE_ARGS!"=="1" (
  set "ENGINE_ARGS=!ENGINE_ARGS! %~1"
  shift
  goto parse_args
)
if /i "%~1"=="--" (
  set "COLLECT_ENGINE_ARGS=1"
  shift
  goto parse_args
)
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="--dist" (
  set "USE_DIST=%~2"
  if "!USE_DIST!"=="" (
    echo ERROR: --dist requires a label (e.g. win11^) >&2
    exit /b 1
  )
  shift
  shift
  goto parse_args
)
if /i "%~1"=="--binary" (
  set "BINARY_OVERRIDE=%~2"
  if "!BINARY_OVERRIDE!"=="" (
    echo ERROR: --binary requires a path >&2
    exit /b 1
  )
  shift
  shift
  goto parse_args
)
set "ENGINE_ARGS=!ENGINE_ARGS! %~1"
shift
goto parse_args

:show_help
echo Launch Operation Deadfall from a clone of this repo.
echo.
echo Usage:
echo   run_game.cmd [options] [--] [engine arguments...]
echo.
echo Options:
echo   --dist LABEL     Use engine from engine\dist\LABEL\ (e.g. win11^)
echo   --binary PATH    Use this executable instead of auto-detecting
echo   -h, --help       Show this help
echo.
echo Put nzp\ inside the repo root or in the parent folder. See README.md.
exit /b 0

:end_parse

set "BASEDIR="
set "NZP_DIR="

if exist "%ROOT%\nzp\" (
  set "BASEDIR=%ROOT%"
  set "NZP_DIR=%ROOT%\nzp"
  goto have_nzp
)
for %%I in ("%ROOT%\..") do set "PARENT=%%~fI"
if exist "!PARENT!\nzp\" (
  set "BASEDIR=!PARENT!"
  set "NZP_DIR=!PARENT!\nzp"
  goto have_nzp
)

echo ERROR: Missing nzp\ game data. Expected either:
echo   %ROOT%\nzp
echo   !PARENT!\nzp
echo Obtain nzp from NZ:P releases (see README Quick Start^).
exit /b 1

:have_nzp

:: Optional: LibreQuake free asset layer. If lq1\ sits next to nzp\ (same basedir),
:: pass -game lq1 so FTEQW loads LibreQuake's BSD-licensed Quake assets alongside nzp\.
:: Download from https://github.com/lavenderdotpet/LibreQuake/releases (mod.zip -> lq1\).
set "LQ1_ARGS="
if exist "!BASEDIR!\lq1\" (
  set "LQ1_ARGS=-game lq1"
  echo LibreQuake data found at !BASEDIR!\lq1 -- loading as supplementary asset layer.
)

set "EXE="

if not "!BINARY_OVERRIDE!"=="" (
  if not exist "!BINARY_OVERRIDE!" (
    echo ERROR: Executable not found: !BINARY_OVERRIDE! >&2
    exit /b 1
  )
  set "EXE=!BINARY_OVERRIDE!"
  goto launch
)

if not "!USE_DIST!"=="" (
  set "D=%ROOT%\engine\dist\!USE_DIST!"
  if not exist "!D!\" (
    echo ERROR: engine\dist\!USE_DIST!\ not found. Build with: build_engine.cmd >&2
    exit /b 1
  )
  if exist "!D!\nzportable-sdl64.exe" set "EXE=!D!\nzportable-sdl64.exe"
  if "!EXE!"=="" if exist "!D!\fteqw.exe" set "EXE=!D!\fteqw.exe"
  if "!EXE!"=="" (
    echo ERROR: No nzportable-sdl64.exe or fteqw.exe in !D!\ >&2
    exit /b 1
  )
  goto launch
)

:: Default search: packaged MinGW output, then release folder (MinGW then MSVC).
if exist "%ROOT%\engine\dist\win11\nzportable-sdl64.exe" set "EXE=%ROOT%\engine\dist\win11\nzportable-sdl64.exe"
if "!EXE!"=="" if exist "%ROOT%\engine\release\nzportable-sdl64.exe" set "EXE=%ROOT%\engine\release\nzportable-sdl64.exe"
if "!EXE!"=="" if exist "%ROOT%\engine\dist\win11-msvc\fteqw.exe" set "EXE=%ROOT%\engine\dist\win11-msvc\fteqw.exe"
if "!EXE!"=="" if exist "%ROOT%\engine\release\fteqw.exe" set "EXE=%ROOT%\engine\release\fteqw.exe"
if "!EXE!"=="" if exist "%ROOT%\engine\dist\win11\fteqw.exe" set "EXE=%ROOT%\engine\dist\win11\fteqw.exe"

if "!EXE!"=="" (
  echo ERROR: No Windows engine binary found.
  echo Build one: double-click build_engine.cmd or run:
  echo   build.bat --preset win11 --mingw --package
  echo Or download a release and use run_game.cmd --binary path\to\nzportable-sdl64.exe
  exit /b 1
)

:launch
for %%F in ("!EXE!") do set "EXEDIR=%%~dpF"
if /i not "!EXE:~-4!"==".exe" (
  rem Non-.exe override: skip SDL2 check
) else if not exist "!EXEDIR!SDL2.dll" (
  echo NOTE: SDL2.dll should be in the same folder as the .exe. If the game fails to start,
  echo copy SDL2.dll next to the executable ^(build_engine.cmd / build.bat --mingw does this^).
)

pushd "%BASEDIR%" >nul 2>&1
"!EXE!" -basedir "!BASEDIR!" !LQ1_ARGS! !ENGINE_ARGS!
set "EC=!ERRORLEVEL!"
popd >nul 2>&1
exit /b !EC!
