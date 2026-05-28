# USB Attach Helper for WSL2
# Lists and attaches USB devices to WSL2 for SD card flashing
#
# Usage:
#   .\wsl2-usb-attach.ps1                # List devices and pick one interactively
#   .\wsl2-usb-attach.ps1 -BusId 1-2     # Attach specific device by bus ID

param(
    [string]$BusId = ""
)

$ErrorActionPreference = "Stop"

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

# ── Check usbipd ─────────────────────────────────────────────────────────────

if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
    Write-Err "usbipd-win is not installed."
    Write-Host ""
    Write-Host "Install it with:" -ForegroundColor White
    Write-Host "  winget install usbipd" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or download from: https://github.com/dorssel/usbipd-win/releases" -ForegroundColor Gray
    exit 1
}

# ── List USB devices ─────────────────────────────────────────────────────────

Write-Status "Listing USB devices..."
Write-Host ""

usbipd wsl list

Write-Host ""

# ── Attach by bus ID ────────────────────────────────────────────────────────

if ($BusId -ne "") {
    Write-Status "Attaching USB device $BusId to WSL2..."
    usbipd wsl attach --busid $BusId

    if ($LASTEXITCODE -eq 0) {
        Write-OK "USB device $BusId attached successfully."
        Write-Host ""
        Write-Host "Verify in WSL2 with:" -ForegroundColor White
        Write-Host "  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL" -ForegroundColor Cyan
    }
    else {
        Write-Err "Failed to attach device $BusId."
        Write-Host "Make sure the device is plugged in and not in use by Windows." -ForegroundColor Gray
    }
    exit 0
}

# ── Interactive mode ─────────────────────────────────────────────────────────

Write-Host "Enter the bus ID of the device you want to attach (e.g., '1-2'), or press Enter to skip:" -ForegroundColor White
$choice = Read-Host "Bus ID"

if ($choice -ne "") {
    Write-Status "Attaching USB device $choice to WSL2..."
    usbipd wsl attach --busid $choice

    if ($LASTEXITCODE -eq 0) {
        Write-OK "USB device $choice attached successfully."
        Write-Host ""
        Write-Host "Verify in WSL2 with:" -ForegroundColor White
        Write-Host "  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL" -ForegroundColor Cyan
    }
    else {
        Write-Err "Failed to attach device $choice."
    }
}
else {
    Write-Warn "No device attached. Run this script again when you need to flash an SD card."
}

Write-Host ""
Write-Host "To detach a device later:" -ForegroundColor White
Write-Host "  usbipd wsl detach --busid <busid>" -ForegroundColor Cyan
Write-Host ""