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
    [switch]$Launch
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
# Working engine binaries: check the locations run_game.cmd also uses.
# NOTE: the NZ:P nightly engine binary is NOT compatible with this mod's
# QuakeC (it crashes on map load) - never use it as the engine source.
$EngineCandidates = @(
    (Join-Path $EngineDistDir "nzportable-sdl64.exe"),
    (Join-Path $EngineDistDir "nzportable.exe"),
    (Join-Path $EngineReleaseDir "nzportable-sdl64.exe"),
    (Join-Path $EngineReleaseDir "fteqw.exe")
)
$haveEngine = $false
foreach ($e in $EngineCandidates) {
    if (Test-Path -LiteralPath $e) { $haveEngine = $true }
}

# An nzp folder can exist with only compiled bytecode in it (deployed by the
# QC step); treat game data as present only when the bundle's default.cfg is
# there too.
$needAssets = (-not (Test-Path -LiteralPath (Join-Path $NzpDir "default.cfg")))

if ($needAssets) {
    if ($SkipDownload) {
        Write-Warning "NZ:P game data is missing, but -SkipDownload was specified."
    } else {
        Write-Host "`n[1/4] Downloading official NZ:P game data..." -ForegroundColor Yellow
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
        $extractDir = Join-Path $env:TEMP "nzp_extract"
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force
        if (Test-Path (Join-Path $extractDir "nzp")) {
            Copy-Item -Path (Join-Path $extractDir "nzp") -Destination $RootDir -Recurse -Force
        }

        if (-not (Test-Path -LiteralPath $NzpDir)) {
            Write-Warning "Extraction did not produce an nzp folder; check the downloaded archive."
        } else {
            Write-Host "Game data installed." -ForegroundColor Green
        }
    }
} else {
    Write-Host "`n[1/4] NZ:P game data is already present." -ForegroundColor Green
}

# Step 1b: Deploy placeholder inventory images for gui\ pics the game draws
# but the NZ:P data does not ship (see specs\asset_audit.md).  Never
# overwrites real artwork that is already present.
$phDir = Join-Path $RootDir "assets\gui"
if (Test-Path -LiteralPath $phDir) {
    New-Item -ItemType Directory -Force -Path (Join-Path $NzpDir "gui") | Out-Null
    Get-ChildItem -Path $phDir -Filter *.jpg | ForEach-Object {
        $dst = Join-Path $NzpDir ("gui" + [IO.Path]::DirectorySeparatorChar + $_.Name)
        if (-not (Test-Path -LiteralPath $dst)) {
            Copy-Item $_.FullName $dst
        }
    }
}

# Step 2: ensure a WORKING engine binary (local build, or this repo's release)
if (-not $haveEngine) {
    $ReleaseZip = Join-Path $env:TEMP "od-engine-win64.zip"
    $ReleaseUrl = "https://github.com/awest813/Operation-Deadfall/releases/download/bleeding-edge/pc-nzp-win64.zip"
    $gotRelease = $false

    if (-not $SkipDownload) {
        Write-Host "`n[2/4] Trying the Operation Deadfall engine release..." -ForegroundColor Yellow
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $ReleaseUrl -OutFile $ReleaseZip -UseBasicParsing
            if (Test-Path -LiteralPath $ReleaseZip) {
                $relDir = Join-Path $env:TEMP "od_engine_extract"
                if (Test-Path $relDir) { Remove-Item $relDir -Recurse -Force }
                Expand-Archive -Path $ReleaseZip -DestinationPath $relDir -Force
                New-Item -ItemType Directory -Force -Path $EngineReleaseDir, $EngineDistDir | Out-Null
                foreach ($f in @("nzportable-sdl64.exe", "nzportable.exe", "fteqw.exe", "SDL2.dll")) {
                    $src = Get-ChildItem -Path $relDir -Recurse -Filter $f -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($src) {
                        Copy-Item $src.FullName (Join-Path $EngineReleaseDir $f) -Force
                        Copy-Item $src.FullName (Join-Path $EngineDistDir $f) -Force
                        if ($f -ne "SDL2.dll") { $gotRelease = $true }
                    }
                }
                # Release zips ship the compiled mod bytecode under nzp\.
                # progs.dat must always overwrite the NZ:P one (that is the
                # whole mod); other files are copied only if absent.
                $relNzp = Get-ChildItem -Path $relDir -Recurse -Directory -Filter "nzp" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($relNzp) {
                    New-Item -ItemType Directory -Force -Path $NzpDir | Out-Null
                    Get-ChildItem -Path $relNzp.FullName -File | ForEach-Object {
                        $dst = Join-Path $NzpDir $_.Name
                        if ($_.Name -eq "progs.dat" -or -not (Test-Path -LiteralPath $dst)) {
                            Copy-Item $_.FullName $dst -Force
                        }
                    }
                }
            }
        } catch {
            Write-Host "No engine release available yet ($($_.Exception.Message))."
        }
    }

    if ($gotRelease) {
        Write-Host "Engine installed from the Operation Deadfall release." -ForegroundColor Green
    } elseif ($BuildEngine) {
        Write-Host "`n[2/4] Building engine from source..." -ForegroundColor Yellow
        $buildCmd = Join-Path $RootDir "build_engine.cmd"
        if (Test-Path -LiteralPath $buildCmd) {
            cmd.exe /c "`"$buildCmd`""
        }
    } else {
        Write-Warning "No engine binary found."
        Write-Host "  Build one (recommended): double-click build_engine.cmd" -ForegroundColor Yellow
        Write-Host "  Or re-run this script with -BuildEngine to build automatically." -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[2/4] Engine binary found." -ForegroundColor Green
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
        $lq1Extract = Join-Path $env:TEMP "lq1_extract"
        if (Test-Path $lq1Extract) { Remove-Item $lq1Extract -Recurse -Force }
        Expand-Archive -Path $lq1Zip -DestinationPath $lq1Extract -Force
        if (Test-Path -LiteralPath (Join-Path $lq1Extract "mod\lq1")) {
            Move-Item (Join-Path $lq1Extract "mod\lq1") $RootDir -Force
        } elseif (Test-Path -LiteralPath (Join-Path $lq1Extract "lq1")) {
            Move-Item (Join-Path $lq1Extract "lq1") $RootDir -Force
        }
        # mod.zip wraps the gamedir as mod\lq1\ - normalise to lq1\ next to nzp\.
        $wrapped = Join-Path $RootDir "mod\lq1"
        if ((-not (Test-Path -LiteralPath $lq1Dir)) -and (Test-Path -LiteralPath $wrapped)) {
            Move-Item $wrapped $lq1Dir
            $modDir = Join-Path $RootDir "mod"
            if ((Get-ChildItem -LiteralPath $modDir -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                Remove-Item -LiteralPath $modDir -Force
            }
        }
        if (Test-Path -LiteralPath $lq1Dir) {
            Write-Host "LibreQuake installed to $lq1Dir." -ForegroundColor Green
        } else {
            Write-Warning "LibreQuake extraction did not produce an lq1\ folder; continuing without it."
        }
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
