@echo off
setlocal EnableExtensions

:: One-step engine build for Windows (MinGW-w64). Produces engine\dist\win11\ with exe + SDL2.dll.
:: Requires: MSYS2 or standalone MinGW-w64 with mingw32-make and gcc on PATH.
::
:: For Visual Studio instead, open "x64 Native Tools Command Prompt" and run:
::   build.bat --preset win11 --package

cd /d "%~dp0"

where mingw32-make >nul 2>&1
if not errorlevel 1 (
  echo Building engine (win11, MinGW, packaged^)...
  call build.bat --preset win11 --mingw --package %*
  if errorlevel 1 exit /b %ERRORLEVEL%
  echo.
  echo Done. Run the game: run_game.cmd
  echo Packaged files: engine\dist\win11\
  exit /b 0
)

where cmake >nul 2>&1
if not errorlevel 1 (
  echo mingw32-make not found, but CMake detected.
  echo Building engine with CMake...
  cmake -B build -S . -DFTE_BUILD_CONFIG="%~dp0engine\common\config_nzportable.h" -DFTE_TOOL_QTV=OFF
  if errorlevel 1 exit /b %ERRORLEVEL%
  cmake --build build --target fteqw --config Release
  if errorlevel 1 exit /b %ERRORLEVEL%
  cmake --build build --target fteqcc --config Release
  if errorlevel 1 exit /b %ERRORLEVEL%

  if not exist "engine\dist\win11" mkdir "engine\dist\win11"
  if not exist "engine\release" mkdir "engine\release"
  if not exist "engine\qclib" mkdir "engine\qclib"

  if exist "build\Release\fteqw.exe" (
    copy /y "build\Release\fteqw.exe" "engine\dist\win11\fteqw.exe" >nul
    copy /y "build\Release\fteqw.exe" "engine\release\fteqw.exe" >nul
  )
  if exist "build\Release\fteqcc.exe" (
    copy /y "build\Release\fteqcc.exe" "engine\qclib\fteqcc.exe" >nul
  )
  echo.
  echo Done. Run the game: run_game.cmd
  echo Packaged files: engine\dist\win11\
  exit /b 0
)

echo.
echo ERROR: Neither mingw32-make nor CMake was found on PATH.
echo.
echo Install MSYS2 with MinGW-w64 or Visual Studio with CMake.
exit /b 1
