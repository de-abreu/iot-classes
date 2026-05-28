#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/de-abreu/iot-classes.git"
REPO_DIR="$HOME/iot-classes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

banner() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║   IoT Lab — WSL2 Environment Bootstrap                 ║${NC}"
    echo -e "${BOLD}║   Universidade Politécnica de Timișoara / USP           ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Step 1: Verify WSL2 ──────────────────────────────────────────────────────

check_wsl2() {
    info "Checking for WSL2 environment..."
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
        error "This script must be run inside WSL2."
        error "On Windows, open PowerShell and run: wsl -d Ubuntu-24.04"
        exit 1
    fi

    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
        success "Running inside WSL2 (distro: $WSL_DISTRO_NAME)"
    else
        warn "WSL_DISTRO_NAME is not set. You may be running WSL1."
        warn "WSL1 is not supported. Upgrade with: wsl --set-default-version 2"
        exit 1
    fi
}

# ── Step 2: Install Nix ──────────────────────────────────────────────────────

install_nix() {
    if command -v nix &>/dev/null; then
        success "Nix is already installed ($(nix --version))"
        return 0
    fi

    info "Installing Nix (single-user install for WSL2)..."
    info "This will download and run the official Nix installer."

    sh <(curl -L https://nixos.org/nix/install) --no-daemon

    if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        success "Nix installed successfully ($(nix --version))"
    elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        success "Nix installed successfully ($(nix --version))"
    else
        error "Nix installation completed but profile not found."
        error "Please restart your shell and run this script again."
        exit 1
    fi
}

# ── Step 3: Install devenv ───────────────────────────────────────────────────

install_devenv() {
    if command -v devenv &>/dev/null; then
        success "devenv is already installed ($(devenv version 2>/dev/null || echo 'version unknown'))"
        return 0
    fi

    info "Installing devenv..."
    nix-env --install --attr devenv -f https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable

    if command -v devenv &>/dev/null; then
        success "devenv installed successfully"
    else
        error "devenv installation failed."
        error "Try running: nix-env --install --attr devenv -f https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable"
        exit 1
    fi
}

# ── Step 4: Install git ──────────────────────────────────────────────────────

install_git() {
    if command -v git &>/dev/null; then
        success "git is already installed ($(git --version))"
        return 0
    fi

    info "Installing git..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq git
    else
        error "No supported package manager found. Please install git manually."
        exit 1
    fi

    success "git installed successfully ($(git --version))"
}

# ── Step 5: Clone the repository ─────────────────────────────────────────────

clone_repo() {
    if [ -d "$REPO_DIR/.git" ]; then
        success "Repository already cloned at $REPO_DIR"
        return 0
    fi

    info "Cloning the iot-classes repository..."
    git clone "$REPO_URL" "$REPO_DIR"
    success "Repository cloned to $REPO_DIR"
}

# ── Step 6: Enter devenv shell ───────────────────────────────────────────────

enter_shell() {
    info "Entering the devenv shell (this may take a while on first run)..."
    cd "$REPO_DIR"

    if [ ! -f .env ]; then
        warn ".env file not found. Creating from .env.example..."
        cp .env.example .env
        warn "Edit .env with your auth token and report server URL."
    fi

    success "Project is ready at $REPO_DIR"
}

# ── Verification ─────────────────────────────────────────────────────────────

verify() {
    echo ""
    echo -e "${BOLD}=== Environment Verification ===${NC}"
    echo ""

    local all_ok=true

    # WSL2
    if grep -qi microsoft /proc/version 2>/dev/null; then
        success "WSL2 detected"
    else
        error "Not running in WSL2"
        all_ok=false
    fi

    # Nix
    if command -v nix &>/dev/null; then
        success "Nix installed ($(nix --version 2>/dev/null | head -1))"
    else
        error "Nix not found"
        all_ok=false
    fi

    # devenv
    if command -v devenv &>/dev/null; then
        success "devenv installed"
    else
        error "devenv not found"
        all_ok=false
    fi

    # git
    if command -v git &>/dev/null; then
        success "git installed ($(git --version))"
    else
        error "git not found"
        all_ok=false
    fi

    # GUI support
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -d /mnt/wslg ]; then
        success "WSLg/GUI support detected"
    else
        warn "No WSLg detected — GUI apps need an X server (or use explorer.exe)"
    fi

    # systemd
    if [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]; then
        success "systemd is running"
    else
        warn "systemd is not running — enable it in /etc/wsl.conf for Avahi support"
    fi

    echo ""
    if [ "$all_ok" = true ]; then
        echo -e "${GREEN}${BOLD}All essential checks passed!${NC}"
    else
        echo -e "${YELLOW}${BOLD}Some checks failed — see errors above.${NC}"
    fi
}

# ── Next steps banner ─────────────────────────────────────────────────────────

next_steps() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║   Next Steps                                            ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1. Enter the development environment:"
    echo ""
    echo -e "     ${BOLD}cd $REPO_DIR && devenv shell${NC}"
    echo ""
    echo "  2. Launch the Zed editor with the AI assistant:"
    echo ""
    echo -e "     ${BOLD}devenv shell start${NC}"
    echo ""
    echo "  3. When flashing an SD card, attach USB devices from Windows:"
    echo ""
    echo "     PowerShell> usbipd wsl list"
    echo "     PowerShell> usbipd wsl attach --busid <busid>"
    echo ""
    echo -e "  4. See ${BOLD}docs/wsl2.md${NC} for detailed WSL2 setup instructions."
    echo ""
    echo -e "  ${YELLOW}As a Computer Science student, you really should consider${NC}"
    echo -e "  ${YELLOW}switching to Linux. Software wants to be free.${NC}"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    banner
    check_wsl2
    install_nix
    install_devenv
    install_git
    clone_repo
    enter_shell
    verify
    next_steps
}

main "$@"