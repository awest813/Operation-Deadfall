@echo off
:: build.bat – convenience build script for Operation Deadfall (Windows / MSVC)
::
:: Usage:
::   build.bat [OPTIONS]
::
:: Options:
::   --target TARGET   FTE_TARGET value (default: vc for MSVC, or win64 for MinGW)
::   --nosdl           Build without SDL2
::   --jobs N          Parallel jobs (default: number of logical processors)
::   --mingw           Use MinGW-w64 instead of MSVC (requires mingw32-make on PATH)
::   --help            Show this message
::
:: MSVC build requires "x64 Native Tools Command Prompt for VS 2022" (or similar).
:: See BUILD.md for full instructions.

setlocal enabledelayedexpansion

:: ---------- defaults ---------------------------------------------------------
set "TARGET="
set "NOSDL=0"
set "USE_MINGW=0"
set "JOBS=%NUMBER_OF_PROCESSORS%"
if "%JOBS%"=="" set "JOBS=4"

:: ---------- argument parsing -------------------------------------------------
:parse_args
if "%~1"=="" goto :end_args
if /i "%~1"=="--help"   goto :show_help
if /i "%~1"=="-h"       goto :show_help
if /i "%~1"=="--nosdl"  ( set "NOSDL=1" & shift & goto :parse_args )
if /i "%~1"=="--mingw"  ( set "USE_MINGW=1" & shift & goto :parse_args )
if /i "%~1"=="--target" ( set "TARGET=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--jobs"   ( set "JOBS=%~2" & shift & shift & goto :parse_args )
echo Unknown option: %~1 >&2
exit /b 1

:show_help
findstr /b "::" "%~f0" | findstr /v "^::" | more
exit /b 0

:end_args

:: ---------- set up make tool and target --------------------------------------
if "%USE_MINGW%"=="1" (
    set "MAKE_CMD=mingw32-make"
    if "%TARGET%"=="" (
        if "%NOSDL%"=="0" (
            set "FTE_TARGET=win64_SDL2"
        ) else (
            set "FTE_TARGET=win64"
        )
    ) else (
        set "FTE_TARGET=%TARGET%"
    )
) else (
    :: MSVC path
    set "MAKE_CMD=nmake /f Makefile"
    if "%TARGET%"=="" (
        set "FTE_TARGET=vc"
    ) else (
        set "FTE_TARGET=%TARGET%"
    )
)

:: ---------- build ------------------------------------------------------------
echo =^> Building Operation Deadfall
echo    FTE_TARGET  = %FTE_TARGET%
echo    FTE_CONFIG  = nzportable
echo    Parallel jobs = %JOBS%
echo.

cd /d "%~dp0engine"

echo --^> make makelibs FTE_TARGET=%FTE_TARGET%
%MAKE_CMD% makelibs FTE_TARGET=%FTE_TARGET%
if errorlevel 1 ( echo ERROR: makelibs failed & exit /b 1 )

echo.
echo --^> make m-rel FTE_TARGET=%FTE_TARGET% FTE_CONFIG=nzportable -j%JOBS%
%MAKE_CMD% m-rel FTE_TARGET=%FTE_TARGET% FTE_CONFIG=nzportable -j%JOBS%
if errorlevel 1 ( echo ERROR: m-rel build failed & exit /b 1 )

:: SDL2 Windows link-order workaround (run make a second time)
if "%FTE_TARGET%"=="win32_SDL2" goto :sdl_rerun
if "%FTE_TARGET%"=="win64_SDL2" goto :sdl_rerun
goto :build_done

:sdl_rerun
echo.
echo --^> (SDL2 Windows link-order workaround) re-running make m-rel...
%MAKE_CMD% m-rel FTE_TARGET=%FTE_TARGET% FTE_CONFIG=nzportable -j%JOBS%
if errorlevel 1 ( echo ERROR: m-rel (second pass) failed & exit /b 1 )

:build_done
echo.
echo =^> Build complete. Binaries are in: engine\release\
dir /b engine\release\ 2>nul
endlocal
