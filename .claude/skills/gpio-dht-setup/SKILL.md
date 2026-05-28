---
name: gpio-dht-setup
description: Guide students through understanding Raspberry Pi GPIO pins and setting up a DHT11 humidity/temperature sensor. Covers GPIO overview, sensor specifications, breadboard wiring, and Python scripting with adafruit-circuitpython-dht.
compatibility: claude
---

## What I do

Help students understand how the Raspberry Pi communicates with external sensors
through its GPIO header, wire a DHT11 humidity/temperature sensor on a
breadboard, and write a Python script to read sensor data. I guide through
hardware setup step-by-step and provide programming hints without giving away
complete solutions.

## When to use me

When the user asks about Raspberry Pi GPIO, connecting sensors, the DHT11,
breadboard wiring, or mentions `GPIO`, `DHT11`, `adafruit-circuitpython-dht`,
sensor readings, or temperature/humidity measurement.

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

- A Raspberry Pi (3, 4, or 5) with Raspberry Pi OS and SSH access
- A DHT11 sensor module
- A breadboard
- 3 female-to-male jumper cables
- A 10K Ohm resistor
- The SSH key and connection set up (see the `ssh-local` skill)

---

## Step 1: Understanding GPIO

Explain to the student that the Raspberry Pi can interact with the physical
world thanks to its **GPIO (General-Purpose Input/Output)** pins. These are
digital pins that can be configured as either:

- **Input** — read signals from sensors, buttons, switches (the Pi _listens_)
- **Output** — send HIGH (3.3V) or LOW (0V) signals to control LEDs, motors,
  relays (the Pi _acts_)

All GPIO pins operate at **3.3V logic**. Sending 5V into a GPIO input pin can
damage the Pi.

### The 40-pin header

The Raspberry Pi has a 40-pin header. Pins are numbered two ways:

- **Physical/pin number**: 1-40 by position on the board (odd on left, even on
  right).
- **BCM number**: The GPIO chip's internal numbering (e.g., GPIO 17, GPIO 22).
  This is the one used in code.

Explain the identifiable pin groupings:

| Group            | Pin Count | Physical Pins         | BCM GPIOs                                 | Purpose                                            |
| ---------------- | --------- | --------------------- | ----------------------------------------- | -------------------------------------------------- |
| **Power (3.3V)** | 2         | 1, 17                 | —                                         | Regulated 3.3V supply (max ~50mA)                  |
| **Power (5V)**   | 2         | 2, 4                  | —                                         | Direct 5V from USB/mains                           |
| **Ground**       | 8         | 6,9,14,20,25,30,34,39 | —                                         | Ground reference, scattered for wiring convenience |
| **General GPIO** | 15        | various               | 4,5,6,12,13,16,17,18,19,22,23,24,25,26,27 | Free-use digital I/O                               |
| **I2C**          | 2         | 3, 5                  | 2, 3                                      | SDA/SCL — sensors, displays                        |
| **SPI**          | 5         | 19,21,23,24,26        | 9,10,11,7,8                               | MOSI/MISO/SCLK/CE0/CE1 — high-speed peripherals    |
| **UART**         | 2         | 8, 10                 | 14, 15                                    | TX/RX — serial communication                       |
| **HAT ID**       | 2         | 27, 28                | 0, 1                                      | Auto-configuration EEPROM for HATs                 |

> **Note**: SPI, I2C, and UART pins can be **reconfigured** as plain GPIO when
> their special function is not needed, but using those buses claims those pins.

Then ask the student to display the GPIO pinout diagram by running:

```bash
feh .claude/skills/gpio-dht-setup/gpio-pinout.png
```

> [!NOTE]
>
> WSL2 users: if `feh` fails with a display error, open the images directly in
> Windows:
>
> ```bash
> explorer.exe .claude/skills/gpio-dht-setup/
> ```
>
> This opens the folder in Windows Explorer where you can double-click the images
> to view them.

---

## Step 2: The DHT11 sensor

Introduce the DHT11 as a **humidity and temperature sensor** that communicates
over a single data wire. It is one of the most common beginner sensors and a
great example of how GPIO enables the Pi to talk to the physical world.

### Specifications

- Operating Voltage: 3.5V to 5.5V
- Operating Current: 0.3mA (measuring), 60uA (standby)
- Output: Serial data
- Temperature Range: 0 degrees C to 50 degrees C
- Humidity Range: 20% to 90%
- Resolution: Temperature and Humidity both are 16-bit
- Accuracy: plus or minus 1 degrees C and plus or minus 1%

Refer the student to the datasheet for more detail:
https://components101.com/sites/default/files/component_datasheet/DHT11-Temperature-Sensor.pdf

### DHT11 pin layout

Offer to show the student an image of the DHT11 that details its 3 pins:

- **VCC** — Power supply pin. Connects to 3.3V or 5V on the Pi.
- **DATA** — Serial data output pin. Connects to a GPIO pin on the Pi. This is
  how the sensor sends readings.
- **GND** — Ground pin. Connects to any GND pin on the Pi.

### Quiz the student

Display the following pin diagram:

```
 3.3V  1  2   5V
GPIO2  3  4   5V
GPIO3  5  6   GND
GPIO4  7  8   GPIO14
  GND  9  10  GPIO15
GPIO17 11 12  GPIO18
GPIO27 13 14  GND
GPIO22 15 16  GPIO23
  3.3V 17 18  GPIO24
GPIO10 19 20  GND
 GPIO9 21 22  GPIO25
GPIO11 23 24  GPIO8
   GND 25 26  GPIO7
 GPIO0 27 28  GPIO1
 GPIO5 29 30  GND
 GPIO6 31 32  GPIO12
GPIO13 33 34  GND
GPIO19 35 36  GPIO16
GPIO26 37 38  GPIO20
   GND 39 40  GPIO21
```

And ask the student:

> "Given the DHT11's three pins (VCC, DATA, GND) and the previous diagram, which
> specific physical pin numbers on the Raspberry Pi would you connect each one
> to?"

Wait for the student's answer and assess correctness. A valid answer would be
something like:

- VCC → Pin 1 or Pin 17 (3.3V) — 3.3V is preferred since GPIO is 3.3V logic
- GND → Any GND pin (e.g., Pin 6, 9, 14, 20, 25, 30, 34, or 39)
- DATA → Any free GPIO pin (e.g., Pin 16 = GPIO23)

Confirm if the student's choices are correct and explain any mistakes. If
correct, proceed to the wiring step.

---

## Step 3: Breadboard wiring

### Components needed

- 1x breadboard
- 3x female-to-male jumper cables (Red - VCC, Black - GND, Brown - Data)
- 1x 10K Ohm resistor (pull-up resistor between VCC and DATA)

### Identifying the 10K Ohm resistor

Help the student identify the 10K Ohm resistor by its color bands. A 10K Ohm
resistor typically has the following color bands:

- **Brown** (1) — Black (0) — Orange (x1000) — Gold (plus or minus 5% tolerance)

So the sequence is: **Brown, Black, Orange, Gold**.

### Wiring instructions

> [!IMPORTANT]
>
> It is very important that the sensor **and** the resistor be correctly placed
> on the breadboard **before** connecting the jumper cables to the GPIO. An
> incorrectly placed circuit could damage the Raspberry Pi by sending electrical
> current where it shouldn't go.

1. Place the DHT11 sensor on the breadboard, ensuring each pin is in a separate
   row.
2. Place the 10K Ohm **pull-up resistor** between the VCC and DATA rows of the
   sensor. This resistor ensures the data line stays HIGH by default and enables
   proper communication.
3. Connect the jumper cables:
   - **Red** → VCC row on breadboard
   - **Black** → GND row on breadboard
   - **Brown** → DATA row on breadboard

Ask the student to confirm when they have the breadboard set up **before**
connecting the jumper cables to the Raspberry Pi pins. Then ask the student to
display the expected breadboard setup images by running:

```bash
feh .claude/skills/gpio-dht-setup/dht11-breadboard-1.png
feh .claude/skills/gpio-dht-setup/dht11-breadboard-2.png
```

> [!NOTE]
>
> WSL2 users: if `feh` fails with a display error, see the note in Step 1 about
> using `explorer.exe` to view images in Windows.

These images show the DHT11 on a breadboard with:

- Red cable for VCC
- Black cable for GND
- Brown cable for Data
- 10K Ohm resistor between VCC and DATA

### Checkpoint

When they confirm, ask the student to display the full wiring diagram by
running:

```bash
feh .claude/skills/gpio-dht-setup/dht11-wiring-diagram.png
```

> [!NOTE]
>
> WSL2 users: if `feh` fails with a display error, see the note in Step 1 about
> using `explorer.exe` to view images in Windows.

This diagram shows a complete valid configuration connecting the DHT11 through
the breadboard to the Raspberry Pi GPIO header.

> [!WARNING]
>
> Do not proceed to connecting the Pi until the student confirms the breadboard
> is wired correctly. A short circuit or missing pull-up resistor can damage the
> Pi.

---

## Step 4: Setting up the Python environment

Once the hardware is connected, guide the student to create a virtual
environment and install the DHT library on the Raspberry Pi:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install adafruit-circuitpython-dht
```

Explain that:

- `python3 -m venv .venv` creates an isolated Python environment in the `.venv`
  directory, keeping project dependencies separate from the system Python.
- `source .venv/bin/activate` activates the virtual environment. The prompt will
  change to show `(.venv)`.
- To **deactivate** the environment later, run `deactivate`.
- To **reactivate** it in a new session, run `source .venv/bin/activate` again.

---

## Step 5: Writing the sensor reading script

Ask the student to create a script that reads temperature and humidity data from
the DHT11 sensor. The script should accept two command-line arguments:

```bash
python3 hum_sensor.py 5 D23
```

Where `5` is the number of samples and `D23` is the GPIO pin to read from.

### Libraries and functions to suggest

Guide the student by pointing them to the following resources. **Do not provide
a complete working example** — only offer partial snippets in response to
specific questions:

- **`argparse`**, class `ArgumentParser` — for parsing command-line arguments.
  Use `add_argument` with the `description` parameter for the script
  description.

  Suggest they set up two arguments:
  - Number of samples (an integer)
  - GPIO pin identifier (a string like `D23`)

- **`board`**, function `getattr` — for dynamically resolving the pin name. The
  pin name passed as argument (e.g. `"D23"`) maps to an attribute on the `board`
  module (e.g. `board.D23`). `getattr(board, pin_name)` retrieves it.

- **`adafruit_dht`**, class `DHT11` — for interacting with the sensor.
  Instantiate with the board pin. The object exposes `.temperature` and
  `.humidity` properties (both `float`, in degrees Celsius and percent
  respectively).

- **Error handling** — `RuntimeError` and `Exception`:

  - A `RuntimeError` can occur occasionally when a sensor read fails. This is
    expected behavior — display an error message but **do not** interrupt
    execution. Just skip that sample and continue.
  - Other `Exception` types may indicate critical problems (e.g., wrong pin,
    sensor disconnected). These **should** interrupt execution.

- **`time`**, function `sleep` — for adding a delay between samples. A 2-second
  interval between readings is recommended to observe small changes without
  overwhelming the sensor.

> [!IMPORTANT] Working locally and deploying
>
> Remind the student they can work on the script on their local machine and
> transfer it to the Raspberry Pi using `scp` with the SSH key generated
> previously:
>
> ```bash
> scp -i ~/.ssh/opencode-remote-raspberry hum_sensor.py <user>@<hostname>.local:~
> ```
>
> If ZED_LOCAL = true, also remind them that, if they run into trouble, they can
> share their code or diagnostics with you writing `@` in their message and
> selecting those from the menu.

### Pseudocode reference

If the student asks for overall guidance on the script, provide pseudocode only:

```
PARSE command-line arguments:
    - number_of_samples (int)
    - pin_name (str, e.g. "D23")

RESOLVE the board pin from pin_name using getattr

INITIALIZE DHT11 sensor on the resolved pin

FOR each sample from 1 to number_of_samples:
    TRY:
        READ temperature and humidity from sensor
        PRINT temperature and humidity readings
    IF RuntimeError:
        PRINT warning message, CONTINUE to next sample
    IF other Exception:
        PRINT error message, EXIT with failure
    SLEEP 2 seconds
```

---

## Step 6: Validation

After the student has written the script and transferred it to the Pi, ask them
to provide:

1. The path to their SSH identity key for the Raspberry Pi.
2. The path (on the Pi) where the script is located.

Connect to the Pi via SSH and run a quick test with 10 samples:

```bash
ssh -i <identity-key> <user>@<hostname>.local "cd <script-dir> && source .venv/bin/activate && python3 hum_sensor.py 10 D23"
```

Review the output for:

- Correct temperature and humidity readings (not static/prefabricated values).
- Proper error handling (if a `RuntimeError` occurs, it should not crash).

Also review the source code to ensure it actually reads from the DHT11 sensor
rather than printing fabricated data at regular intervals. To do this, read the
script from the Pi:

```bash
ssh -i <identity-key> <user>@<hostname>.local "cat <script-dir>/hum_sensor.py"
```

If everything checks out, mark the todo list as complete.

---

## Routing

If this skill was activated in a step-by-step manner, upon completion call the
`class-1-wrap-up` skill.

---

## Safety rules

- The student must confirm the breadboard is correctly wired **before**
  connecting jumper cables to the Raspberry Pi GPIO
- Never provide the student with a complete working Python script — only partial
  examples addressing specific concerns
- If the student asks for the full script, respond with pseudocode only
- Ensure the student understands that 5V on a GPIO input pin can damage the Pi
- Always verify pin assignments before making connections
