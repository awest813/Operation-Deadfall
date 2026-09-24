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
    foreach ($p in @(
        (Join-Path $RootDir "engine\qclib\fteqcc.exe"),
        (Join-Path $RootDir "engine\qclib\fteqcc.bin"),
        (Join-Path $RootDir "build\Release\fteqcc.exe"),
        (Join-Path $RootDir "build-test\Release\fteqcc.exe")
    )) {
        if (Test-Path -LiteralPath $p) { return $p }
    }

    # If not found, attempt to build fteqcc via CMake if cmake is available
    $cmake = Get-Command cmake -ErrorAction SilentlyContinue
    if ($cmake) {
        Write-Host "fteqcc not found. Building fteqcc with CMake..."
        $cmakeBuildDir = Join-Path $RootDir "build\qcc"
        try {
            & $cmake.Source -B $cmakeBuildDir -S $RootDir -DFTE_TOOL_QCC=ON -DFTE_TOOL_QCCGUI=OFF -DFTE_TOOL_QTV=OFF *>$null
            & $cmake.Source --build $cmakeBuildDir --target fteqcc --config Release *>$null
            $built = Join-Path $cmakeBuildDir "Release\fteqcc.exe"
            if (-not (Test-Path -LiteralPath $built)) {
                $built = Join-Path $cmakeBuildDir "fteqcc.exe"
            }
            if (Test-Path -LiteralPath $built) {
                Copy-Item $built (Join-Path $RootDir "engine\qclib\fteqcc.exe") -Force
                return (Join-Path $RootDir "engine\qclib\fteqcc.exe")
            }
        } catch {}
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
        cmd.exe /c "`"$Fteqcc`" -srcfile `"$SrcFile`" > `"$logPath`" 2>&1"
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
if (Test-Path -LiteralPath (Join-Path $RootDir "quakec\qwprogs.dat")) {
    Copy-Item (Join-Path $RootDir "quakec\qwprogs.dat") (Join-Path $BuildFolder "progs.dat") -Force
}

$csaddonSrc = Join-Path $RootDir "quakec\csaddon\src"
if (Test-Path -LiteralPath $csaddonSrc) {
    $ok = (Invoke-QcCompile $csaddonSrc "csaddon.src" "csaddon.txt" "csaddon" $Fteqcc) -and $ok
    Copy-IfExists (Join-Path $RootDir "quakec\csaddon\csaddon.dat") $BuildFolder
    $csDat = Join-Path $RootDir "quakec\csaddon\csaddon.dat"
    if (Test-Path -LiteralPath $csDat) {
        $pk3 = Join-Path $BuildFolder "csaddon.pk3"
        $zipTmp = Join-Path $BuildFolder "csaddon.zip"
        Push-Location (Join-Path $RootDir "quakec\csaddon")
        try {
            if (Test-Path -LiteralPath $zipTmp) { Remove-Item -LiteralPath $zipTmp -Force }
            Compress-Archive -Path "csaddon.dat" -DestinationPath $zipTmp -Force
            Move-Item -LiteralPath $zipTmp -Destination $pk3 -Force
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
        $zipTmp = Join-Path $BuildFolder "menusys.zip"
        Push-Location (Join-Path $RootDir "quakec")
        try {
            if (Test-Path -LiteralPath $zipTmp) { Remove-Item -LiteralPath $zipTmp -Force }
            Compress-Archive -Path "menu.dat" -DestinationPath $zipTmp -Force
            Move-Item -LiteralPath $zipTmp -Destination $pk3 -Force
        }
        finally { Pop-Location }
    }
}

# Auto-deploy compiled bytecode to nzp game folder if present
$nzpTargets = @(
    (Join-Path $RootDir "nzp"),
    (Join-Path (Split-Path $RootDir -Parent) "nzp")
)
foreach ($nzp in $nzpTargets) {
    if (Test-Path -LiteralPath $nzp) {
        Write-Host "Deploying compiled QC bytecode to $nzp ..."
        if (Test-Path -LiteralPath (Join-Path $RootDir "quakec\qwprogs.dat")) {
            Copy-Item (Join-Path $RootDir "quakec\qwprogs.dat") (Join-Path $nzp "progs.dat") -Force
            Copy-Item (Join-Path $RootDir "quakec\qwprogs.dat") (Join-Path $nzp "qwprogs.dat") -Force
        }
        if (Test-Path -LiteralPath (Join-Path $RootDir "quakec\csprogs.dat")) {
            Copy-Item (Join-Path $RootDir "quakec\csprogs.dat") (Join-Path $nzp "csprogs.dat") -Force
        }
        if (Test-Path -LiteralPath (Join-Path $RootDir "quakec\menu.dat")) {
            Copy-Item (Join-Path $RootDir "quakec\menu.dat") (Join-Path $nzp "menu.dat") -Force
        }
        if (Test-Path -LiteralPath (Join-Path $RootDir "quakec\csaddon\csaddon.dat")) {
            Copy-Item (Join-Path $RootDir "quakec\csaddon\csaddon.dat") (Join-Path $nzp "csaddon.dat") -Force
        }
    }
}

if (-not $ok) { exit 1 }
Write-Host "All QC modules built and deployed successfully."
exit 0
