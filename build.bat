@echo off
:: build.bat – convenience build script for Operation Deadfall (Windows / MSVC or MinGW)
::
:: Usage:
::   build.bat [OPTIONS]
::
:: Recommended presets:
::   build.bat --preset win11              ^& rem MSVC-friendly native Windows build
::   build.bat --preset win11 --mingw      ^& rem MinGW-w64 build with SDL2 auto-copy
::   build.bat --preset win11 --mingw --package
::
:: Options:
::   --preset NAME      Friendly build preset. Valid values:
::                      win11, win11-nosdl
::   --target TARGET    FTE_TARGET value (default: vc for MSVC, or win64 for MinGW)
::   --nosdl            Build without SDL2
::   --jobs N           Parallel jobs (default: number of logical processors)
::   --mingw            Use MinGW-w64 instead of MSVC (requires mingw32-make on PATH)
::   --package          Copy the finished runnable files into engine\dist\<label>\
::   --help             Show this message
::
:: MSVC build requires "x64 Native Tools Command Prompt for VS 2022" (or similar).
:: See BUILD.md for full instructions.

setlocal enabledelayedexpansion

:: ---------- defaults ---------------------------------------------------------
set "PRESET="
set "TARGET="
set "NOSDL=0"
set "USE_MINGW=0"
set "PACKAGE_OUTPUT=0"
set "JOBS=%NUMBER_OF_PROCESSORS%"
set "OUTPUT_LABEL="
set "PRIMARY_ARTIFACT="
if "%JOBS%"=="" set "JOBS=4"

:: ---------- argument parsing -------------------------------------------------
:parse_args
if "%~1"=="" goto :end_args
if /i "%~1"=="--help"    goto :show_help
if /i "%~1"=="-h"        goto :show_help
if /i "%~1"=="--nosdl"   ( set "NOSDL=1" & shift & goto :parse_args )
if /i "%~1"=="--mingw"   ( set "USE_MINGW=1" & shift & goto :parse_args )
if /i "%~1"=="--package" ( set "PACKAGE_OUTPUT=1" & shift & goto :parse_args )
if /i "%~1"=="--preset"  ( set "PRESET=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--target"  ( set "TARGET=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--jobs"    ( set "JOBS=%~2" & shift & shift & goto :parse_args )
echo Unknown option: %~1 >&2
exit /b 1

:show_help
for /f "tokens=* delims=:" %%h in ('findstr /b "::" "%~f0"') do echo.%%h
exit /b 0

:end_args

if defined PRESET (
    if /i "%PRESET%"=="win11" (
        set "TARGET=win64"
        set "OUTPUT_LABEL=win11"
        if "%NOSDL%"=="1" set "OUTPUT_LABEL=win11-nosdl"
    ) else if /i "%PRESET%"=="win11-nosdl" (
        set "TARGET=win64"
        set "NOSDL=1"
        set "OUTPUT_LABEL=win11-nosdl"
    ) else (
        echo ERROR: Unknown preset %PRESET%. Valid presets: win11, win11-nosdl >&2
        exit /b 1
    )
)

:: ---------- set up make tool and target --------------------------------------
if "%USE_MINGW%"=="1" (
    set "MAKE_CMD=mingw32-make"
    if "%TARGET%"=="" set "TARGET=win64"
    if "%NOSDL%"=="0" (
        if /i "%TARGET%"=="win64" (
            set "FTE_TARGET=win64_SDL2"
        ) else if /i "%TARGET%"=="win32" (
            set "FTE_TARGET=win32_SDL2"
        ) else (
            set "FTE_TARGET=%TARGET%"
        )
    ) else (
        set "FTE_TARGET=%TARGET%"
    )
) else (
    set "MAKE_CMD=nmake /f Makefile"
    if "%TARGET%"=="" (
        set "FTE_TARGET=vc"
    ) else (
        set "FTE_TARGET=%TARGET%"
    )
    if "%OUTPUT_LABEL%"=="" set "OUTPUT_LABEL=win11-msvc"
)

if "%OUTPUT_LABEL%"=="" (
    if /i "%FTE_TARGET%"=="win64_SDL2" (
        set "OUTPUT_LABEL=win11"
    ) else if /i "%FTE_TARGET%"=="win64" (
        set "OUTPUT_LABEL=win11-nosdl"
    ) else (
        set "OUTPUT_LABEL=%FTE_TARGET%"
    )
)

if /i "%FTE_TARGET%"=="win64_SDL2" set "PRIMARY_ARTIFACT=release\nzportable-sdl64.exe"
if /i "%FTE_TARGET%"=="win64" set "PRIMARY_ARTIFACT=release\nzportable64.exe"
if /i "%FTE_TARGET%"=="win32_SDL2" set "PRIMARY_ARTIFACT=release\nzportable-sdl.exe"
if /i "%FTE_TARGET%"=="win32" set "PRIMARY_ARTIFACT=release\nzportable.exe"
if /i "%FTE_TARGET%"=="vc" set "PRIMARY_ARTIFACT=release\fteqw.exe"

:: ---------- build ------------------------------------------------------------
echo =^> Building Operation Deadfall
echo    Preset         = %PRESET%
echo    FTE_TARGET     = %FTE_TARGET%
echo    FTE_CONFIG     = nzportable
echo    Parallel jobs  = %JOBS%
echo    Package bundle = %PACKAGE_OUTPUT%
echo.

cd /d "%~dp0engine"

echo --^> make makelibs FTE_TARGET=%FTE_TARGET%
%MAKE_CMD% makelibs FTE_TARGET=%FTE_TARGET%
if errorlevel 1 ( echo ERROR: makelibs failed & exit /b 1 )

echo.
echo --^> make m-rel FTE_TARGET=%FTE_TARGET% FTE_CONFIG=nzportable -j%JOBS%
%MAKE_CMD% m-rel FTE_TARGET=%FTE_TARGET% FTE_CONFIG=nzportable -j%JOBS%
if errorlevel 1 ( echo ERROR: m-rel build failed & exit /b 1 )

if /i "%FTE_TARGET%"=="win32_SDL2" goto :sdl_rerun
if /i "%FTE_TARGET%"=="win64_SDL2" goto :sdl_rerun
goto :post_build

:sdl_rerun
echo.
echo --^> (SDL2 Windows link-order workaround) re-running make m-rel...
%MAKE_CMD% m-rel FTE_TARGET=%FTE_TARGET% FTE_CONFIG=nzportable -j%JOBS%
if errorlevel 1 ( echo ERROR: m-rel (second pass) failed & exit /b 1 )

echo.
if /i "%FTE_TARGET%"=="win64_SDL2" (
    set "SDL2_DLL=libs-x86_64-w64-mingw32\SDL2-2.30.7\x86_64-w64-mingw32\bin\SDL2.dll"
) else (
    set "SDL2_DLL=libs-i686-w64-mingw32\SDL2-2.30.7\i686-w64-mingw32\bin\SDL2.dll"
)
if exist "%SDL2_DLL%" (
    echo --^> Copying SDL2.dll to release\
    copy /y "%SDL2_DLL%" release\ >nul
) else (
    echo WARNING: SDL2.dll not found at %SDL2_DLL% – users will need to supply it manually.
)

:post_build
echo.
echo =^> Build complete. Binaries are in: release\
dir /b release\ 2>nul

if not "%PACKAGE_OUTPUT%"=="1" goto :done
if "%PRIMARY_ARTIFACT%"=="" (
    echo ERROR: Packaging is not available for FTE_TARGET=%FTE_TARGET% >&2
    exit /b 1
)
if not exist "%PRIMARY_ARTIFACT%" (
    echo ERROR: Expected build artifact not found: %PRIMARY_ARTIFACT% >&2
    exit /b 1
)

set "PACKAGE_DIR=dist\%OUTPUT_LABEL%"
if not exist "%PACKAGE_DIR%" mkdir "%PACKAGE_DIR%"
copy /y "%PRIMARY_ARTIFACT%" "%PACKAGE_DIR%\" >nul
if exist "release\SDL2.dll" copy /y "release\SDL2.dll" "%PACKAGE_DIR%\" >nul
(
    echo Operation Deadfall build bundle
    echo ===============================
    echo.
    echo Preset: %OUTPUT_LABEL%
    echo Primary artifact: %PRIMARY_ARTIFACT%
    echo.
    echo Put the executable next to your nzp\ game-data folder.
    echo See BUILD.md and RUNNING_THE_GAME.md for details.
) > "%PACKAGE_DIR%\README-BUILD.txt"

echo.
echo =^> Packaged runnable files into: %PACKAGE_DIR%\
dir /b "%PACKAGE_DIR%\" 2>nul

:done
endlocal
