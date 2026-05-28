---
name: ssh-local
description: Guide students through establishing SSH connectivity to a Raspberry Pi over a direct Ethernet connection. Covers interface configuration, mDNS resolution, key-based authentication, and troubleshooting common issues.
compatibility: claude
---

## What I do

Help students connect their computer to a Raspberry Pi via a direct Ethernet
cable using SSH. I diagnose interface issues, configure the local network
interface, verify mDNS resolution, set up key-based authentication, and
troubleshoot common connectivity problems.

## When to use me

When the user asks for help connecting to a Raspberry Pi (or any Linux SBC) over
Ethernet/SSH, mentions `ssh`, `raspberry-pi`, `avahi`, `.local` hostnames,
`NetworkManager`, or reports "Connection timed out", "Device is busy", or "Name
or service not known" errors.

---

## Before starting

If activating this skill in a step-by-step manner, use the `todowrite` tool to
create a todo list that covers all the steps in this skill. Each step below
should become a separate todo item so the student can track their progress
throughout the exercise. Otherwise, skip the todo list or the step by step
progression and jump directly to the relevant section.

---

## Prerequisites

Remind the student to have:

- A Raspberry Pi powered, with the micro SD card containing its OS image
  inserted, and SSH enabled (Raspberry Pi OS enables this by default when
  configured through `rpi-imager`)
- An Ethernet cable connecting their computer directly to the Pi
- The Pi's username and password (set during imaging)
- The Pi's hostname (set during imaging)

---

## Step 1: Verify the physical connection and interface

The agent (you) should run the following checks:

### 1a. Is the Ethernet interface UP?

```bash
ip link show
```

Look for the Ethernet interface (commonly `enp2s0`, `enp3s0`, `eth0`, etc.).
Verify it has state `UP`. If it shows `DOWN`:

- The cable may be disconnected or faulty
- NetworkManager may have disabled the interface

If the interface is `DOWN`, troubleshoot with NetworkManager:

```bash
nmcli device status
nmcli connection show
```

A connection listed as `connected (externally)` means NetworkManager is not
managing it. Bring it up with:

```bash
sudo nmcli connection up <connection-name>
```

If no connection profile exists, create one:

```bash
sudo nmcli connection add type ethernet ifname <interface> con-name <interface> ipv4.method manual ipv4.addresses 169.254.1.1/16
sudo nmcli connection up <interface>
```

### 1b. Is the interface on the correct subnet?

```bash
ip addr show <interface>
```

Raspberry Pi OS defaults to link-local addressing (`169.254.x.x`) when no DHCP
server is present. Your interface **must** be in the `169.254.0.0/16` subnet to
communicate with the Pi.

If the interface has an IP in a different subnet (e.g., `10.0.0.1/30`), the Pi
will be unreachable. Reconfigure it:

```bash
sudo nmcli connection modify <interface> ipv4.addresses 169.254.1.1/16
sudo nmcli connection modify <interface> ipv4.method manual
sudo nmcli connection up <interface>
```

> [!WARNING]
>
> Do **not** use `/30` subnet masks for direct Ethernet connections to a
> Raspberry Pi. The Pi's link-local address is in the `169.254.0.0/16` range and
> a `/30` on a different subnet makes it unreachable. Use `/16` to cover the
> full link-local range.

### 1c. Can the Pi be pinged?

```bash
ping -c 3 169.254.209.222   # or whatever IP the Pi has
```

If pings fail, re-check steps 1a and 1b. If they pass, continue.

---

## Step 2: Verify mDNS (Avahi) resolution

```bash
ping -c 3 <hostname>.local
```

If this fails with "Name or service not known" or "Temporary failure in name
resolution":

1. **Check that Avahi is running locally:**

```bash
systemctl status avahi-daemon
```

If the command is not found or the service is inactive, Avahi needs to be
installed and/or enabled. The method depends on your distribution:

2. **Determine the distribution:**

```bash
grep "^ID=" /etc/os-release
```

- **NixOS** — add to your configuration and rebuild:

```nix
services.avahi = {
  enable = true;
  nssmdns4 = true;
  allowInterfaces = [ "enp2s0" "wlp3s0" ];  # add your interfaces
};
```

- **Debian / Ubuntu / Raspberry Pi OS** — Avahi is pre-installed on most desktop
  editions. If missing:

```bash
sudo apt install avahi-daemon
sudo systemctl enable --now avahi-daemon
```

- **Fedora / RHEL** — installed by default on Workstation. If missing:

```bash
sudo dnf install avahi-daemon
sudo systemctl enable --now avahi-daemon
```

- **Arch Linux**:

```bash
sudo pacman -S avahi nss-mdns
sudo systemctl enable --now avahi-daemon
```

- **Other distributions** — install the `avahi-daemon` package using your
  package manager, then enable and start the service. Consult your
  distribution's documentation for the recommended steps.

3. **Ensure the Avahi daemon on the Pi is also running** (it is enabled by
   default on Raspberry Pi OS, but verify if resolution still fails):

```bash
ssh <user>@<hostname>.local 'systemctl status avahi-daemon'
```

4. **Check that Avahi listens on the wired interface** — on some systems it may
   default to Wi-Fi only. For NixOS, use the `allowInterfaces` option shown
   above. For other distributions, edit `/etc/avahi/avahi-daemon.conf` and set
   `allow-interfaces=enp2s0,eth0` (or whatever your wired interface is named).

---

## Step 3: Create an SSH key for passwordless authentication

Instruct the student on creating a ssh key. This avoids typing passwords
repeatedly and, more importantly, prevents the agent from ever receiving the
user's actual password through the chat.

### On the student's terminal

```bash
ssh-keygen -t ed25519 -f ~/.ssh/opencode-remote-raspberry -C "opencode-remote-raspberry"
ssh-copy-id -i ~/.ssh/opencode-remote-raspberry.pub <user>@<hostname>.local
```

> [!IMPORTANT]
>
> - The key sent to the Pi must be the **public key** (`.pub` extension), not
>   the private key (no extension).
> - Replace `<user>@<hostname>.local` with the actual username and hostname
>   configured during imaging (e.g., `raspberry_user@rasberry-2a.local`).
> - The key can be named as the user wishes, but they should inform the agent if
>   a different name was picked, as the agent will also need to use it and does
>   not have permission to search `~/.ssh/`.

### Verify key-based login works

```bash
ssh -i ~/.ssh/opencode-remote-raspberry <user>@<hostname>.local 'echo connected'
```

This should print `connected` **without** asking for a password.

---

## Step 4: Connect through the editor (Zed)

The student should:

1. Open a new window in Zed (`Ctrl-Shift-N`)
2. Open a Remote project (`Ctrl-Shift-Alt-O`)
3. Select **Connect SSH Server** and input:

```
ssh -i ~/.ssh/opencode-remote-raspberry <user>@<hostname>.local
```

If successful, the student should see:

- A project folder structure in the navigator matching the Pi's home directory
- If the agent window is still open, it will fail to connect and send an error
  message — this is expected, since the ACP server is trying to run remotely
  where opencode is neither installed nor configured.

Ask the student to create a simple "Hello World" Python script on the Pi and
tell you where it is located so that you can also connect and test running
Python code. If both connections work, the setup is complete.

---

## Step 5: Next steps

Call the skill `gpio-dht-setup`, going through its contents in a walkthrough
fashion.

---

## Troubleshooting reference

### "Device is busy"

This error from `nmcli` usually means the connection profile conflicts with
another. Solutions:

```bash
sudo nmcli connection down <old-profile>  # Bring down conflicting profile
sudo nmcli connection up <interface>      # Bring up the correct one
```

Or delete the old profile and recreate:

```bash
sudo nmcli connection delete <old-profile>
sudo nmcli connection add type ethernet ifname <interface> con-name <interface> ipv4.method manual ipv4.addresses 169.254.1.1/16
sudo nmcli connection up <interface>
```

### "Connection timed out"

Typically caused by a subnet mismatch. Verify both ends are on `169.254.0.0/16`:

```bash
ip addr show <interface>    # local side
ssh <user>@<hostname>.local 'ip addr show eth0'   # Pi side (once connected)
```

### "Name or service not known" for `.local` hostnames

Avahi/mDNS is not resolving. See [Step 2](#step-2-verify-mdns-avahi-resolution).

### SSH key not being offered

If `ssh -i <key>` still asks for a password:

```bash
ssh -vvv -i ~/.ssh/opencode-remote-raspberry <user>@<hostname>.local
```

Look for lines like `Offering public key` and `Server accepts key` to diagnose.
Common causes:

- Wrong key file (private vs. public — always use the private key for `-i`)
- Key not in `authorized_keys` on the Pi (re-run `ssh-copy-id`)
- Incorrect file permissions (`chmod 600 ~/.ssh/opencode-remote-raspberry`)

---

## Routing

If this skill was activated in a step-by-step manner, upon completion call the
skill `ssh-local`, going through its contents step by step.

---

## Safety rules

- The student runs `ssh-copy-id`, `ssh-keygen`, and `nmcli` commands themselves
  — never run these on behalf of the user
- Never ask for or display the student's password in the chat
- Always verify the student has connected successfully before moving on
