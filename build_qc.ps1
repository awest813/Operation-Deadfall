# Build QuakeC modules on Windows (same outputs as build_qc.sh).
# Usage: powershell -File build_qc.ps1
#        or double-click build_qc.cmd

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildFolder = if ($env:BUILDFOLDER) { $env:BUILDFOLDER } else { Join-Path $RootDir "build\qc" }
$BuildLogFolder = if ($env:BUILDLOGFOLDER) { $env:BUILDLOGFOLDER } else { Join-Path $BuildFolder "build_logs" }

New-Item -ItemType Directory -Force -Path $BuildFolder, $BuildLogFolder | Out-Null

function Find-Fteqcc {
    if ($env:FTEQCC -and (Test-Path -LiteralPath $env:FTEQCC)) { return $env:FTEQCC }
    $inPath = Get-Command fteqcc -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }
    foreach ($name in @("fteqcc.exe", "fteqcc.bin")) {
        $p = Join-Path $RootDir "engine\qclib\$name"
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Invoke-QcCompile {
    param(
        [string] $ModuleDir,
        [string] $SrcFile,
        [string] $LogName,
        [string] $Description,
        [string] $Fteqcc
    )
    $logPath = Join-Path $BuildLogFolder $LogName
    Write-Host -NoNewline "Building $Description... "
    Push-Location $ModuleDir
    try {
        & $Fteqcc -srcfile $SrcFile *> $logPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host "failed (see $logPath)"
            return $false
        }
        Write-Host "done"
        return $true
    }
    finally {
        Pop-Location
    }
}

function Copy-IfExists {
    param([string] $SourcePath, [string] $DestinationDir)
    if (Test-Path -LiteralPath $SourcePath) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationDir -Force
    }
}

$Fteqcc = Find-Fteqcc

$Fteqw = $env:FTEQW
if (-not $Fteqw) {
    $cmd = Get-Command fteqw -ErrorAction SilentlyContinue
    if ($cmd) { $Fteqw = $cmd.Source }
}
$Qss = $env:QSS
if (-not $Qss) {
    $cmd = Get-Command quakespasm-spiked-linux64 -ErrorAction SilentlyContinue
    if ($cmd) { $Qss = $cmd.Source }
}

Write-Host "--- QC builds ---"
Write-Host "Artifacts: $BuildFolder"
Write-Host "Logs:      $BuildLogFolder"

if ($Fteqw) { Write-Host "Optional defs generation enabled via FTEQW: $Fteqw" }
else { Write-Host "Optional defs generation skipped (FTEQW not found)." }

if ($Qss) { Write-Host "Optional QSS defs generation enabled via: $Qss" }
else { Write-Host "Optional QSS defs generation skipped (QSS not found)." }

if (-not $Fteqcc) {
    @"
No FTEQCC compiler was found.
Set `$env:FTEQCC to the full path to fteqcc, or build the bundled compiler:
  Open MSYS2 UCRT64 (or MINGW64), then:
    cd `"$($RootDir -replace '\\','/')/engine/qclib`"
    mingw32-make qcc
  That produces fteqcc.bin in engine\qclib\. Then run this script again.
"@ | Write-Host
    exit 1
}

$ok = $true
$ok = (Invoke-QcCompile (Join-Path $RootDir "quakec\deadfall") "progs.src" "deadfall-progs.txt" "deadfall server QC" $Fteqcc) -and $ok
$ok = (Invoke-QcCompile (Join-Path $RootDir "quakec\deadfall") "csprogs.src" "deadfall-csprogs.txt" "deadfall CSQC" $Fteqcc) -and $ok

Copy-IfExists (Join-Path $RootDir "quakec\qwprogs.dat") $BuildFolder
Copy-IfExists (Join-Path $RootDir "quakec\csprogs.dat") $BuildFolder

$csaddonSrc = Join-Path $RootDir "quakec\csaddon\src"
if (Test-Path -LiteralPath $csaddonSrc) {
    $ok = (Invoke-QcCompile $csaddonSrc "csaddon.src" "csaddon.txt" "csaddon" $Fteqcc) -and $ok
    Copy-IfExists (Join-Path $RootDir "quakec\csaddon\csaddon.dat") $BuildFolder
    $csDat = Join-Path $RootDir "quakec\csaddon\csaddon.dat"
    if (Test-Path -LiteralPath $csDat) {
        $pk3 = Join-Path $BuildFolder "csaddon.pk3"
        Push-Location (Join-Path $RootDir "quakec\csaddon")
        try {
            Compress-Archive -Path "csaddon.dat" -DestinationPath $pk3 -Force
        }
        finally { Pop-Location }
    }
}

$menusys = Join-Path $RootDir "quakec\menusys"
if (Test-Path -LiteralPath $menusys) {
    $ok = (Invoke-QcCompile $menusys "menu.src" "menusys.txt" "menusys" $Fteqcc) -and $ok
    Copy-IfExists (Join-Path $RootDir "quakec\menu.dat") $BuildFolder
    $menuDat = Join-Path $RootDir "quakec\menu.dat"
    if (Test-Path -LiteralPath $menuDat) {
        $pk3 = Join-Path $BuildFolder "menusys.pk3"
        Push-Location (Join-Path $RootDir "quakec")
        try {
            Compress-Archive -Path "menu.dat" -DestinationPath $pk3 -Force
        }
        finally { Pop-Location }
    }
}

if (-not $ok) { exit 1 }
exit 0
