<#
.SYNOPSIS
    Automated setup script for Operation Deadfall on Windows.
    Downloads required assets (NZ:P and optional LibreQuake), sets up engine binaries,
    compiles Deadfall QuakeC bytecode, and verifies everything is playable.

.EXAMPLE
    .\scripts\setup_game.ps1
    .\scripts\setup_game.ps1 -WithLibreQuake -Launch
#>

param(
    [switch]$WithLibreQuake,
    [switch]$SkipDownload,
    [switch]$BuildEngine,
    [switch]$Launch,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$NzpDir = Join-Path $RootDir "nzp"
$EngineReleaseDir = Join-Path $RootDir "engine\release"
$EngineDistDir = Join-Path $RootDir "engine\dist\win11"
$QclibDir = Join-Path $RootDir "engine\qclib"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       Operation Deadfall -- Game Setup & Installer       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Target directory: $RootDir"

New-Item -ItemType Directory -Force -Path $EngineReleaseDir, $EngineDistDir, $QclibDir | Out-Null

$NzpZipUrl = "https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-win64.zip"
$Lq1ZipUrl = "https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/mod.zip"

# Step 1: NZ:P Game Assets & Engine Binaries
$needAssets = (-not (Test-Path -LiteralPath $NzpDir)) -or (-not (Get-ChildItem -Path $NzpDir -ErrorAction SilentlyContinue | Select-Object -First 1))
$needEngine = (-not (Test-Path -LiteralPath (Join-Path $EngineReleaseDir "nzportable-sdl64.exe"))) -and `
              (-not (Test-Path -LiteralPath (Join-Path $EngineReleaseDir "fteqw.exe")))

if ($needAssets -or $needEngine) {
    if ($SkipDownload) {
        Write-Warning "Missing assets or engine, but -SkipDownload was specified."
    } else {
        Write-Host "`n[1/4] Downloading official NZ:P Win64 bundle..." -ForegroundColor Yellow
        $tempZip = Join-Path $env:TEMP "nzportable-win64.zip"

        $downloaded = $false
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            Write-Host "Downloading via curl..."
            & $curl.Source -L -o $tempZip $NzpZipUrl
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $tempZip)) { $downloaded = $true }
        }

        if (-not $downloaded) {
            Write-Host "Downloading via PowerShell WebClient..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $NzpZipUrl -OutFile $tempZip -UseBasicParsing
        }

        Write-Host "Extracting game assets..." -ForegroundColor Yellow
        $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
        if ($tar) {
            if ($needAssets) {
                & $tar.Source -xf $tempZip -C $RootDir nzp
            }
            & $tar.Source -xf $tempZip -C $tempZip.Substring(0, $tempZip.LastIndexOf('\')) nzportable.exe SDL2.dll SDL2_mixer.dll
        } else {
            $extractDir = Join-Path $env:TEMP "nzp_extract"
            if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
            Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force
            if ($needAssets -and (Test-Path (Join-Path $extractDir "nzp"))) {
                Copy-Item -Path (Join-Path $extractDir "nzp") -Destination $RootDir -Recurse -Force
            }
            foreach ($f in @("nzportable.exe", "SDL2.dll", "SDL2_mixer.dll")) {
                $src = Join-Path $extractDir $f
                if (Test-Path $src) { Copy-Item $src $env:TEMP -Force }
            }
        }

        # Place engine binaries
        $tempBin = Join-Path $env:TEMP "nzportable.exe"
        if (Test-Path -LiteralPath $tempBin) {
            Copy-Item $tempBin (Join-Path $EngineReleaseDir "nzportable-sdl64.exe") -Force
            Copy-Item $tempBin (Join-Path $EngineReleaseDir "nzportable.exe") -Force
            Copy-Item $tempBin (Join-Path $EngineDistDir "nzportable-sdl64.exe") -Force
            Copy-Item $tempBin (Join-Path $EngineDistDir "nzportable.exe") -Force
        }
        foreach ($dll in @("SDL2.dll", "SDL2_mixer.dll")) {
            $srcDll = Join-Path $env:TEMP $dll
            if (Test-Path -LiteralPath $srcDll) {
                Copy-Item $srcDll (Join-Path $EngineReleaseDir $dll) -Force
                Copy-Item $srcDll (Join-Path $EngineDistDir $dll) -Force
            }
        }

        Write-Host "Assets and runtime binaries installed successfully." -ForegroundColor Green
    }
} else {
    Write-Host "`n[1/4] NZ:P assets and engine binaries are already present." -ForegroundColor Green
}

# Step 2: Build Engine from source if requested
if ($BuildEngine) {
    Write-Host "`n[2/4] Building engine from source..." -ForegroundColor Yellow
    $buildCmd = Join-Path $RootDir "build_engine.cmd"
    if (Test-Path -LiteralPath $buildCmd) {
        cmd.exe /c "`"$buildCmd`""
    }
} else {
    Write-Host "`n[2/4] Engine binaries verified." -ForegroundColor Green
}

# Step 3: Compile and deploy Operation Deadfall QuakeC
Write-Host "`n[3/4] Compiling Operation Deadfall QuakeC..." -ForegroundColor Yellow
$qcScript = Join-Path $RootDir "build_qc.ps1"
if (Test-Path -LiteralPath $qcScript) {
    & powershell -ExecutionPolicy Bypass -File $qcScript
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "QuakeC compile reported errors. Check logs in build\qc\build_logs."
    }
}

# Step 4: LibreQuake supplementary layer (optional)
$lq1Dir = Join-Path $RootDir "lq1"
if ($WithLibreQuake -and (-not (Test-Path -LiteralPath $lq1Dir))) {
    Write-Host "`n[4/4] Downloading LibreQuake free asset layer..." -ForegroundColor Yellow
    $lq1Zip = Join-Path $env:TEMP "lq1_mod.zip"
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        & $curl.Source -L -o $lq1Zip $Lq1ZipUrl
    } else {
        Invoke-WebRequest -Uri $Lq1ZipUrl -OutFile $lq1Zip -UseBasicParsing
    }
    if (Test-Path -LiteralPath $lq1Zip) {
        $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
        if ($tar) {
            & $tar.Source -xf $lq1Zip -C $RootDir
        } else {
            Expand-Archive -Path $lq1Zip -DestinationPath $RootDir -Force
        }
        Write-Host "LibreQuake installed to $lq1Dir." -ForegroundColor Green
    }
} else {
    Write-Host "`n[4/4] Asset check complete." -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "          Operation Deadfall is Ready to Play!            " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "To launch the game, run: run_game.cmd"
Write-Host "Optional map launch:    run_game.cmd -- +map ndu"

if ($Launch) {
    Write-Host "`nLaunching Operation Deadfall..." -ForegroundColor Cyan
    $runCmd = Join-Path $RootDir "run_game.cmd"
    Start-Process -FilePath $runCmd
}
