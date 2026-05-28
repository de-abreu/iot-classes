# Bootstrap script for WSL2 environment setup
# Run this script in an elevated PowerShell (Run as Administrator)

$ErrorActionPreference = "Stop"

# ── Admin check ──────────────────────────────────────────────────────────────

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run:" -ForegroundColor White
    Write-Host "  irm https://raw.githubusercontent.com/de-abreu/iot-classes/main/scripts/bootstrap-wsl2.ps1 | iex" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

$RepoUrl = "https://github.com/de-abreu/iot-classes.git"

function Write-Status($Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-OK($Message) {
    Write-Host "[  OK] $Message" -ForegroundColor Green
}

function Write-Warn($Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err($Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ── Banner ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "   IoT Lab - WSL2 Environment Bootstrap (Windows Side)" -ForegroundColor White
Write-Host "   Universitatea Politehnica din Timisoara / USP" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White
Write-Host ""

# ── Step 1: Check Windows version ────────────────────────────────────────────

Write-Status "Checking Windows version..."

$winVer = [System.Environment]::OSVersion.Version
$winBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber

if ($winBuild -ge 22000) {
    Write-OK "Windows 11 detected (build $winBuild) - WSLg built-in"
    $HasWSLg = $true
}
elseif ($winBuild -ge 19044) {
    Write-OK "Windows 10 detected (build $winBuild) - WSL2 supported"
    Write-Warn "Windows 10 does not include WSLg. You will need an X server (VcXsrv) for GUI apps."
    Write-Warn "See docs/wsl2.md for instructions."
    $HasWSLg = $false
}
else {
    Write-Err "Windows build $winBuild is not supported. Build 19044+ (Windows 10 21H2) or Windows 11 is required."
    Write-Err "Update Windows or consider using a Linux system instead."
    Read-Host "Press Enter to close this window"
    exit 1
}

# ── Step 2: Check/install WSL ───────────────────────────────────────────────

Write-Status "Checking WSL installation..."

$wslInstalled = $null -ne (Get-Command wsl -ErrorAction SilentlyContinue)

if (-not $wslInstalled) {
    Write-Status "Installing WSL2 with Ubuntu-24.04..."
    wsl --install -d Ubuntu-24.04
    if ($LASTEXITCODE -ne 0) {
        Write-Err "WSL installation failed. You may need to enable Virtualization (VT-x) in BIOS."
        Write-Err "Also try enabling the Windows features manually:"
        Write-Host "  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" -ForegroundColor Gray
        Write-Host "  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" -ForegroundColor Gray
        Read-Host "Press Enter to close this window"
        exit 1
    }
    Write-OK "WSL2 and Ubuntu-24.04 installed. A restart may be required."
    Write-Warn "If this is a fresh install, restart your computer and re-run this script."
    Read-Host "Press Enter to close this window"
    exit 0
}
else {
    Write-OK "WSL is already installed"
}

# Ensure WSL2 is the default version
Write-Status "Ensuring WSL2 is the default version..."
wsl --set-default-version 2 2>$null
Write-OK "WSL2 is the default version"

# ── Step 3: Check for a Ubuntu distro ───────────────────────────────────────

Write-Status "Checking for Ubuntu distro..."

$distros = wsl --list --quiet 2>$null
$hasUbuntu = $distros -match "Ubuntu"

if (-not $hasUbuntu) {
    Write-Status "No Ubuntu distro found. Installing Ubuntu-24.04..."
    wsl --install -d Ubuntu-24.04
    Write-OK "Ubuntu-24.04 installed."
    Write-Warn "If this is a new install, you may need to set up a username/password first."
    Write-Warn "Run this script again after completing the initial Ubuntu setup."
    Read-Host "Press Enter to close this window"
    exit 0
}
else {
    Write-OK "Ubuntu distro is available"
}

# ── Step 4: Install usbipd-win ───────────────────────────────────────────────

Write-Status "Checking usbipd-win..."

$usbipdInstalled = $null -ne (Get-Command usbipd -ErrorAction SilentlyContinue)

if (-not $usbipdInstalled) {
    Write-Status "Installing usbipd-win (for USB passthrough to WSL2)..."
    $wingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

    if ($wingetAvailable) {
        winget install usbipd --accept-package-agreements --accept-source-agreements
        Write-OK "usbipd-win installed"
    }
    else {
        Write-Warn "winget is not available. Install usbipd-win manually:"
        Write-Host "  https://github.com/dorssel/usbipd-win/releases" -ForegroundColor Gray
    }
}
else {
    Write-OK "usbipd-win is already installed"
}

# ── Step 5: Launch Linux-side bootstrap ─────────────────────────────────────

Write-Host ""
Write-Status "Launching Linux-side bootstrap inside WSL2..."
Write-Host ""

$linuxScript = @'
set -e
REPO_URL="https://github.com/de-abreu/iot-classes.git"
if ! command -v curl &>/dev/null; then
    echo "[INFO] Installing curl..."
    sudo apt-get update -qq && sudo apt-get install -y -qq curl
fi
curl -fsSL "$REPO_URL/raw/main/scripts/bootstrap-wsl2-linux.sh" | bash
'@

wsl -d Ubuntu-24.04 -- bash -c $linuxScript.Replace("`r`n", "`n")

# ── Next steps ──────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "   Bootstrap Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Open Ubuntu in WSL2:" -ForegroundColor White
Write-Host "     wsl -d Ubuntu-24.04" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Enter the development environment:" -ForegroundColor White
Write-Host "     cd ~/iot-classes && devenv shell" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Or launch the Zed editor directly:" -ForegroundColor White
Write-Host "     cd ~/iot-classes && devenv shell start" -ForegroundColor Cyan
Write-Host ""
Write-Host "  4. To flash an SD card, attach USB devices:" -ForegroundColor White
Write-Host "     usbipd wsl list" -ForegroundColor Cyan
Write-Host "     usbipd wsl attach --busid <busid>" -ForegroundColor Cyan
Write-Host ""

if (-not $HasWSLg) {
    Write-Host "  NOTE: For GUI apps on Windows 10, install VcXsrv or use explorer.exe" -ForegroundColor Yellow
    Write-Host "  See docs/wsl2.md for instructions." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "  As a Computer Science student, you really should consider" -ForegroundColor Yellow
Write-Host "  switching to Linux. Software wants to be free." -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to close this window"