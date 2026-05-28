---
name: wsl2-setup
description: Detect and configure the WSL2 environment for the IoT lab. Checks for GUI support (WSLg), systemd, and USB passthrough, guiding the student through any missing setup.
compatibility: claude
---

## What I do

Walk the student through configuring their WSL2 environment for the IoT lab. I
detect whether key features — GUI support, systemd, and USB passthrough — are
available and guide the student through enabling them if they are not.

## When to use me

When `WSL_DISTRO_NAME` is set (i.e., the student is running inside WSL2), the
`introduction` skill will route here before proceeding to class selection.

---

> *[As a Computer Science student, you really should consider switching to Linux.
> Software wants to be free. But until you see the light, WSL2 will have to do.]*

Welcome to the WSL2 environment check. This quick check ensures your setup is
ready for the lab exercises. We will go through four checks — it should only
take a few minutes.

---

## Check 1: WSL2 verification

Confirm you are inside WSL2 by running:

```bash
echo $WSL_DISTRO_NAME
```

If this prints a distro name (e.g., `Ubuntu`), you are in WSL2. If it prints
nothing, you are not in WSL2 — this skill does not apply to you. The
`introduction` skill should not have routed you here; let the agent know.

If the output starts with a version number indicating WSL1 (e.g., the kernel
version does not contain "microsoft"), WSL1 is not supported. To upgrade:

```powershell
wsl --set-default-version 2
```

Then restart WSL:

```powershell
wsl --shutdown
```

---

## Check 2: GUI support (WSLg)

GUI applications like `zed`, `feh`, and `rpi-imager` need display support to
work inside WSL2. Run:

```bash
echo $WAYLAND_DISPLAY
# Or check:
ls /mnt/wslg/
```

### If `$WAYLAND_DISPLAY` is set or `/mnt/wslg` exists

WSLg is available. GUI applications will work — no action needed. Let the agent
know.

### If neither is present (Windows 10)

You need an X server to display GUI applications. Install
[VcXsrv](https://sourceforge.net/projects/vcxsrv/):

1. Download and install VcXsrv
2. Launch **XLaunch** with these settings:
   - Display: **Multiple windows**
   - Start no client
   - Extra: **Disable access control** (important!)
3. In WSL2, set the display variable:

```bash
export DISPLAY=$(ip route show default | awk '{print $3}'):0
```

Add this line to `~/.bashrc` so it persists:

```bash
echo 'export DISPLAY=$(ip route show default | awk '\''{print $3}'\''):0' >> ~/.bashrc
```

> [!NOTE]
>
> If you don't want to set up an X server, you can still view image files by
> opening them in Windows:
>
> ```bash
> explorer.exe .claude/skills/gpio-dht-setup/
> ```
>
> And for `rpi-imager`, you can use the Windows-native version from
> [raspberrypi.com/software](https://www.raspberrypi.com/software/).

---

## Check 3: systemd

Avahi (needed for `.local` hostname resolution) relies on systemd. Check if
systemd is running:

```bash
ps -p 1 -o comm=
```

### If the output is `systemd`

Systemd is running. Avahi will work with `systemctl`. No action needed — move
on to Check 4.

### If the output is `init` or something else

Systemd is not running. You need to enable it. Create or edit `/etc/wsl.conf`:

```bash
sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[boot]
systemd=true
EOF
```

Then restart WSL from **PowerShell** on Windows:

```powershell
wsl --shutdown
```

Reopen your WSL2 terminal and verify:

```bash
ps -p 1 -o comm=
# Should now output: systemd
```

> [!TIP]
>
> If you prefer not to enable systemd, you can start Avahi manually when
> needed:
>
> ```bash
> sudo apt install avahi-daemon
> sudo avahi-daemon
> ```
>
> Or skip `.local` resolution and connect to the Pi by its IP address directly.

---

## Check 4: USB passthrough

Flashing an SD card with `rpi-imager` requires the SD card reader to be
accessible inside WSL2. Run:

```bash
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
```

### If an SD card or USB storage device appears

USB passthrough is working. Note the device name (e.g., `sdb`) — you will need
it later when flashing the SD card.

### If no SD card appears

You need to attach the USB device from Windows. Ensure:

1. The SD card reader is plugged into your computer
2. `usbipd-win` is installed on Windows (run `winget install usbipd` in an
   elevated PowerShell)

Then, from **PowerShell** on Windows (no admin needed for attaching):

```powershell
usbipd wsl list
# Find the busid of your SD card reader

usbipd wsl attach --busid <busid>
```

Back in WSL2, verify again:

```bash
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
```

The SD card reader should now appear.

> [!NOTE]
>
> If `usbipd` is not found on Windows, install it first:
>
> ```powershell
> winget install usbipd
> ```
>
> If `winget` is not available, download usbipd-win from
> [github.com/dorssel/usbipd-win](https://github.com/dorssel/usbipd-win/releases).

If you don't have an SD card reader connected yet, that is fine — you can set
up USB passthrough later when you reach the `rpi-imager` skill.

---

## Summary

Once all four checks are resolved, your WSL2 environment is ready for the IoT
lab. Here is what to remember:

| Feature | Status | Notes |
|---------|--------|-------|
| WSL2 | Verified | You're inside WSL2 |
| GUI (WSLg) | Checked | If missing, set up X server or use alternatives |
| systemd | Checked | If missing, enabled in `/etc/wsl.conf` |
| USB passthrough | Checked | Attach SD card reader with `usbipd` before flashing |

---

## Routing

All checks are complete. Return to the `introduction` skill to continue with
report consent and class selection.

---

## Safety rules

- Do not run `usbipd` commands on behalf of the student — they must run those
  on the Windows host in PowerShell
- Do not modify `/etc/wsl.conf` without explaining what it does and asking the
  student for confirmation
- If the student is unsure about any step, slow down and explain each command
  before running it