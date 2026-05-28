---
name: rpi-imager
description: Guide students through flashing Raspberry Pi OS images using rpi-imager GUI on Linux. Checks prerequisites, detects viable target devices, and provides a walkthrough of the GUI application.
compatibility: claude
---

## What I do

Help students flash Raspberry Pi OS images onto an SD card using the
`rpi-imager` GUI. I check prerequisites, detect viable target devices, and guide
through the GUI steps. `rpi-imager` is already available in this project's dev
environment.

## When to use me

When the user asks for help installing/flashing/burning a Raspberry Pi OS image,
or mentions `rpi-imager`.

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

- MicroSD card (8 GB minimum, 16+ GB for desktop images)
- SD card reader (built-in or USB adapter)
- Target image ready (or suggest download URLs)
- A Raspberry Pi with Wi-Fi capabilities (such as the A or B series, models 3 or
  higher, or any other with a Wi-Fi dongle)

---

## General warnings

**Always** provide the users with the following warnings:

1. `rpi-imager` requires `sudo` as the writing images to disk requires block
   access.
2. If not for a particular reason, prefer installing the recommended OS option.
3. Writing to SD cards can be quite slow — the process may take several minutes
   depending on the card speed and image size. next steps of the class.
4. Remind the student to pick a **hostname and username that are distinct from
   those on their own computer**, to avoid confusion later when creating SSH
   sessions.
5. If the write check (verification) after installation fails, it usually
   indicates a problem with the SD card or reader — try a different SD card or a
   different card reader.

### More on `rpi-imager`'s requirement of superuser privileges

Explain the user that, if launched without superuser privileges, they will be
met with an error message as soon as the application launches. As the message
explains, `rpi-imager` requires superuser permissions to be able to write images
into disk.

On the other hand, if launched with sudo, the user might find that the
application does not launch at all, with an error message that reads, among
other things:

Authorization required, but no authorization protocol specified

```
And ending with a message that reads that the application launch has been aborted:
```

fish: Job 1, 'sudo rpi-imager' terminated by signal SIGABRT (Abort)

````
In turn, that is so because some display servers, such as Wayland, as a safety meadure block attempts to launch GUI applications using such privileges (see [raspberrypi/rpi-imager#1336](https://github.com/raspberrypi/rpi-imager/issues/1336).

A solution for that is to temporarily override the default behavior using the `xhost` command:

```bash
xhost +SI:localuser:root    # Grant root access to your X11 display (Wayland falls back to XWayland)
sudo rpi-imager             # GUI now works
xhost -SI:localuser:root    # Revoke after finishing (recommended)
````

Then run `echo "$XDG_SESSION_TYPE"` and display its result to the user.

---

## Step 1: Check viable target devices

You, the agent, runs `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL` and filter
candidates:

1. `TYPE` is `disk` (not a partition)
2. Not the root/system disk
3. Large enough for the target image

Warn if multiple candidates are found and let the user confirm their target.

---

## Step 2: GUI instructions

1. Open a terminal window.
1. Run `sudo rpi-imager`
1. **Choose OS** — pick from the list, or click "Use custom" for a local `.img`
   file or URL.
1. **Choose Storage** — select the SD card from the device list
1. **Set defaults** — configure hostname, _keep SSH enabled_, setup the local
   wi-fi network authentication, set username and password
1. **Write** — confirm, wait for the write and verification to complete

> [!IMPORTANT]
>
> If the environment variable `ZED_LOCAL` is set, suggest the student uses the
> shortcut `Ctrl+'` to open an embedded terminal window within Zed.

---

## Routing

If this skill was activated in a step-by-step manner, upon completion call the
skill `ssh-local`, going through its contents step by step.

---

## Safety rules

- The user calls rpi-imager themselves
