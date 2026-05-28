# Contributing

If you are a (human) IoT professor or teaching assistant that would like to make
changes to this project, you're in luck: it is fully free and open-source. Forks
and contributions are more than welcome. Here is what you'll need to know to
make sense of it.

## Agents

**Agents** are specialized AI assistants that can be configured for specific
tasks and workflows. They allow you to make use of custom prompts, models, and
tool access.

## Skills

This agent makes use of a **skill-based scaffolding** to deliver classes. A
skill is relevant context written in Markdown that the agent loads whenever
asked to perform a given task, such as offering guidance for a specific class.
Skills can be loaded recursively, so that a skill intended to guide a student
through a class can load other skills relevant to the steps necessary to
complete that class. Because skills are modular, content from previous classes
can be loaded on demand in all following classes.

Available skills are defined in [`.claude/skills/`](.claude/skills/):

| Skill                  | Purpose                                                  |
| ---------------------- | -------------------------------------------------------- |
| `introduction`         | Greeting, class selection, report consent, routing       |
| `rpi-imager`           | Flashing the Raspberry Pi OS SD card                     |
| `ssh-local`            | Connecting to the Raspberry Pi via SSH                   |
| `gpio-dht-setup`       | Wiring and reading the DHT11 temperature/humidity sensor |
| `web-server`           | Setting up a web server on the Raspberry Pi              |
| `mobile-notifications` | Push notifications to a mobile device                    |
| `cloud-data`           | Publishing sensor data to the cloud                      |
| `submit-report`        | Submitting a session report to the report server         |

The [introduction](.claude/skills/introduction/SKILL.md) skill is the starting
point from which all other skills are loaded.

## Tools

Agents make use of **tools** in order to take actions with adequate permissions.
This agent uses tools to discover interfaces, read files, validate results, and
submit reports. Custom tools are defined in
[`.opencode/tools/`](.opencode/tools/).

### submit-report

The only custom tool of this project, defined at
[submit-report.ts](./.opencode/tools/submit-report.ts). The configuration to the
server that receives those reports can be found at [de-abreu/report-server]()

## Development environment

The dependencies required by the project and the classes it covers are managed
through `devenv`, a solution that leverages the Nix language to declaratively
create shell environments and, within those, install dependencies, set
environment variables, add scripts to the PATH. By default, all packages are
version locked to ensure reproducibility.

## References

- [Agents](https://opencode.ai/docs/agents/)
- [Skills](https://opencode.ai/docs/skills/)
- [Tools](https://opencode.ai/docs/tools/)
- [Devenv](https://devenv.sh/getting-started/)

## Windows (WSL2) Compatibility

This project supports WSL2 as a first-class platform. Skills include
WSL2-specific instructions where tools behave differently (e.g., `nmcli` is not
available in WSL2, `rpi-imager` requires USB passthrough for SD card access).

When adding new skills or modifying existing ones:

- Check if any commands used are Linux-specific (nmcli, systemctl, etc.)
- Add a `### WSL2 Users` subsection with alternative instructions
- Test with `WSL_DISTRO_NAME` set to detect the platform
- Reference [docs/wsl2.md](docs/wsl2.md) for detailed WSL2 setup

The `wsl2-setup` skill automatically detects and guides students through
configuring their WSL2 environment when `WSL_DISTRO_NAME` is set.
