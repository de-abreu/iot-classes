# WSL2 Setup Guide

> As a Computer Science student, you really should consider switching to Linux.
> Software wants to be free. But until you see the light, WSL2 will have to do.

This guide covers everything you need to run the IoT lab environment on Windows
using the Windows Subsystem for Linux version 2 (WSL2).

## Prerequisites

- **Windows 10** (build 19044 or later) or **Windows 11**
- **Virtualization (VT-x)** enabled in BIOS/UEFI
- At least **4 GB RAM** (8+ GB recommended)
- **Internet connection**

## Quick Start

### Option A: Automated bootstrap (recommended)

Open **PowerShell as Administrator** and run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
irm https://raw.githubusercontent.com/de-abreu/iot-classes/main/scripts/bootstrap-wsl2.ps1 | iex
```

This script will install WSL2, Ubuntu, usbipd, and launch the Linux-side setup
automatically.

### Option B: Manual installation

Follow the steps below.

---

## Step 1: Install WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart your computer if prompted.

### First-time Ubuntu setup

After the restart (or after a fresh install), a Ubuntu terminal will appear
asking you to create a Unix username and password. This is your Linux user
account — it does **not** need to match your Windows credentials.

1. **Username**: type a lowercase username (no spaces, e.g. `student`) and press
   Enter. This will be your home directory name (`/home/student`).
2. **Password**: type a password and press Enter. Note that nothing will appear
   on screen as you type — this is normal. Type it again to confirm.

Once the prompt `username@computername:~$` appears, your Ubuntu environment is
ready. Close the terminal.

> [!NOTE]
>
> If the Ubuntu terminal does not appear automatically after a restart, open it
> manually from the Start Menu (search for "Ubuntu") or launch it from
> PowerShell:
>
> ```powershell
> wsl -d Ubuntu-24.04
> ```

Verify the installation:

```powershell
wsl --status
```

Ensure the default version is 2:

```powershell
wsl --set-default-version 2
```

## Step 2: Install usbipd-win (for SD card flashing)

`usbipd-win` allows WSL2 to access USB devices (like SD card readers) connected
to the Windows host. This is needed for `rpi-imager`.

Open **PowerShell as Administrator** and run:

```powershell
winget install usbipd
```

After installation, you can list USB devices and attach them to WSL2:

```powershell
usbipd wsl list
usbipd wsl attach --busid <busid>
```

See the [USB passthrough](#usb-passthrough) section for details.

## Step 3: Install Nix and devenv

Inside your WSL2 Ubuntu terminal:

```bash
# Install Nix (single-user install, per devenv documentation)
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# Source the Nix profile
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Install devenv
nix-env --install --attr devenv -f https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable
```

## Step 4: Clone the repository and enter the environment

```bash
git clone https://github.com/de-abreu/iot-classes.git
cd iot-classes
devenv shell
```

To launch the Zed editor with the AI teaching assistant:

```bash
devenv shell start
```

## Step 5: Create .env file (optional — for class reports)

```bash
cp .env.example .env
```

Edit `.env` with your auth token and report server URL from Campus Virtual.

---

## GUI Support

### Windows 11 — WSLg (automatic)

Windows 11 includes WSLg, which provides built-in GUI support. Applications
like `zed`, `feh`, and `rpi-imager` should work out of the box. Verify:

```bash
echo $WAYLAND_DISPLAY
# Should output "wayland-0" or similar

# Or check:
ls /mnt/wslg/
```

If `$WAYLAND_DISPLAY` is set or `/mnt/wslg` exists, GUI apps are supported.

### Windows 10 — X server required

Windows 10 does not include WSLg. You need an X server:

1. Download and install [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
2. Launch XLaunch with these settings:
   - Display: Multiple windows
   - Start no client
   - Extra: **Disable access control**
3. In WSL2, set the display:

```bash
export DISPLAY=$(ip route show default | awk '{print $3}'):0
```

Add this to `~/.bashrc` to make it persistent.

### Alternative: View images in Windows

If you don't want to set up an X server, you can open image files directly in
Windows:

```bash
explorer.exe .claude/skills/gpio-dht-setup/
```

This opens the folder in Windows Explorer where you can double-click images.

---

## USB Passthrough

WSL2 cannot directly access USB devices. To use an SD card reader with
`rpi-imager`, you must attach it from Windows using `usbipd-win`.

### Attaching an SD card reader

1. Insert the SD card reader into your computer
2. Open **PowerShell** (no admin needed) and list devices:

```powershell
usbipd wsl list
```

3. Find your SD card reader in the list (look for "USB" or "SD" in the
   description)
4. Attach it:

```powershell
usbipd wsl attach --busid <busid>
```

5. In WSL2, verify:

```bash
lsblk
```

The SD card should now appear in the device list.

### Detaching

To detach a USB device:

```powershell
usbipd wsl detach --busid <busid>
```

> [!NOTE]
>
> USB passthrough requires `usbipd-win` to be installed on Windows. If the
> `usbipd` command is not found, install it with:
> `winget install usbipd`

---

## Networking

### Why `nmcli` doesn't work in WSL2

WSL2 runs in a lightweight virtual machine with its own network stack.
NetworkManager (and `nmcli`) manage the host's network interfaces, which are
not the same as those inside WSL2. Therefore, `nmcli` is not included in the
WSL2 environment.

### Configuring a direct Ethernet connection to the Pi

#### Option A: Configure from Windows Settings (recommended)

1. Open **Windows Settings → Network & Internet → Advanced network settings**
2. Find the Ethernet adapter connected to the Raspberry Pi
3. Click **View additional properties** → **IPv4 settings**
4. Set a static IP:
   - IP address: `169.254.1.1`
   - Subnet mask: `255.255.0.0` (i.e., prefix length `/16`)
   - Default gateway: leave blank
   - DNS: leave blank

Then verify from WSL2:

```bash
ping -c 3 169.254.x.x   # the Pi's address
```

#### Option B: Mirrored networking mode (WSL 2.0+)

Create the file `%USERPROFILE%\.wslconfig` on Windows:

```ini
[wsl2]
networkingMode=mirrored
```

Then restart WSL:

```powershell
wsl --shutdown
```

In mirrored mode, WSL2 shares the host's network interfaces, so the Ethernet
adapter connected to the Pi becomes visible inside WSL2 with the same IP. You
can then use `ip` commands to configure it:

```bash
ip addr show
ip addr add 169.254.1.1/16 dev <interface>
ip link set <interface> up
```

#### Option C: Configure from WSL2 using iproute2

If the Ethernet interface appears inside WSL2 (it may not in the default NAT
mode), configure it manually:

```bash
sudo ip addr add 169.254.1.1/16 dev <interface>
sudo ip link set <interface> up
```

---

## systemd in WSL2

By default, WSL2 does not run systemd. Some services (like Avahi, needed for
`.local` hostname resolution) require it.

To enable systemd, create or edit `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Then restart WSL:

```powershell
wsl --shutdown
```

Verify:

```bash
ps -p 1 -o comm=
# Should output: systemd
```

If systemd is not enabled, you can still start Avahi manually:

```bash
sudo apt install avahi-daemon
sudo avahi-daemon
```

Or connect to the Pi using its IP address directly instead of `.local`.

---

## Known Limitations

| Feature | Status | Workaround |
|---------|--------|------------|
| `nmcli` | Not available | Use `ip` commands; configure from Windows Settings; or mirrored mode |
| SD card access | Requires usbipd | Attach USB device from Windows via `usbipd wsl attach` |
| `rpi-imager` GUI | Works on Win 11 (WSLg) | Win 10 needs X server; or use Windows-native rpi-imager.exe |
| `feh` (images) | Works on Win 11 (WSLg) | Win 10 needs X server; or use `explorer.exe` |
| `systemctl` | Not available by default | Enable systemd in `/etc/wsl.conf` |
| Avahi/mDNS | Needs manual start | Start manually; or connect by IP address |
| Physical Ethernet | May not appear in WSL2 | Configure from Windows; or use mirrored networking mode |
| GPIO/sensor | N/A | Script runs on Pi via SSH — not a limitation |

### Using Windows-native rpi-imager

If `rpi-imager` inside WSL2 doesn't work for you, you can use the Windows
version instead:

1. Download from [raspberrypi.com/software](https://www.raspberrypi.com/software/)
2. Flash the SD card from Windows
3. Continue with the rest of the lab inside WSL2

This is often the simplest approach for the imaging step.

---

## Troubleshooting

### `wsl --install` fails

Make sure Virtualization (VT-x) is enabled in your BIOS/UEFI settings. Also
ensure the "Virtual Machine Platform" and "Windows Subsystem for Linux" optional
features are enabled:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Then restart your computer and try again.

### GUI apps don't open

On Windows 11, ensure WSLg is working:

```bash
ls /mnt/wslg/
echo $WAYLAND_DISPLAY
```

On Windows 10, you need an X server (see [GUI Support](#gui-support)).

### `lsblk` shows no SD card

The SD card reader must be attached to WSL2 using `usbipd`:

```powershell
usbipd wsl list
usbipd wsl attach --busid <busid>
```

### Can't connect to Pi via Ethernet

The physical Ethernet adapter may not be visible inside WSL2. Use one of these
approaches:

1. Configure the adapter from **Windows Settings** (see [Networking](#networking))
2. Use **mirrored networking mode** (WSL 2.0+)
3. Connect by IP address instead of `.local`

### Avahi/.local resolution doesn't work

Enable systemd (see [systemd in WSL2](#systemd-in-wsl2)) and install Avahi:

```bash
sudo apt install avahi-daemon
sudo systemctl enable --now avahi-daemon
```

If systemd is not available, startAvahi manually:

```bash
sudo avahi-daemon
```

Or skip `.local` resolution entirely and connect by IP:

```bash
ssh <user>@169.254.x.x
```