# An Introduction to Internet of Things

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

This repository contains the course material to an introductory Internet of
Things class offered at the Polytechnic University of Timișoara (Universitatea
Politehnica din Timișoara － UPT). Including:

- An development shell with all dependencies managed using
  [devenv](https://devenv.sh/);
- The course syllabus organized as Claude Code compatible AI Agent Skills;
- An Opencode Agent configuration (named simply "Learn") for an AI Teaching
  Assistant;

## Prerequisites

### Programs

- [git](https://git-scm.com/)
- [devenv](https://devenv.sh/getting-started/)

### Windows (WSL2)

If you are on Windows, you can run this environment inside WSL2. Open PowerShell
as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/de-abreu/iot-classes/main/scripts/bootstrap-wsl2.ps1 | iex
```

This will install WSL2, Ubuntu, Nix, devenv, and clone the repository. See
[docs/wsl2.md](docs/wsl2.md) for detailed instructions, troubleshooting, and
known limitations.

### Hardware

- Raspberry Pi (3, 4, or 5) — other models with Bluetooth (or a Bluetooth
  dongle) also work
- MicroSD card (8 GB minimum; 16+ GB recommended)
- SD card reader (built-in or USB adapter)
- Ethernet cable
- DHT11 temperature/humidity sensor module
- Breadboard
- 3× female-to-male jumper cables
- 10K Ohm resistor

## Getting started

1. Have the prerequisites installed in your machine.

2. Clone this repository

```bash
git clone https://github.com/de-abreu/iot-classes.git
```

Then you got two options:

### Work with recommended settings

Then either load the development environment and launch a mildly preconfigured
[zed editor](https://zed.dev/):

```bash
devenv shell start
```

Open an Agent tab with `Alt+O` and introduce yourself. The agent will take you
from there.

### Working with your own IDE and Opencode Client

The following loads the development environment but does not launch zed:

```bash
devenv shell
```

Use this is you would rather work with your own IDE and ACP configuration.

## Contributing

Check out [CONTRIBUTING.md](/CONTRIBUTING.md).

## License

This project is licensed under the **GNU General Public License v3.0**. See the
[LICENSE](LICENSE) file for details.
