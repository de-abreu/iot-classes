---
name: wrap-up
description: Activated when the student completes all steps of a class. Invites the student to a review quiz and then routes to report submission.
compatibility: claude
---

## What I do

After a student finishes a class, I invite them to participate in a review quiz
that reinforces the key concepts they just learned. I then conclude the session
and route them to report submission.

## When to use me

When the student completes all steps of a class, or when a skill's final step
triggers wrap-up.

---

## Review invitation

Congratulate the student on completing the class. Then ask if they would like to
participate in a short, optional review quiz covering the key concepts they just
learned. Use the `question` tool for this.

### If the student declines

Skip the quiz. Skip directly to the **Conclusion** section below.

### If the student agrees

Determine which class the student just completed by reviewing the conversation
history (which skills were activated, what topics were discussed). Then present
the corresponding quiz questions using the `question` tool, one section at a
time.

**Workflow for each section:**

1. Ask all questions in the section at once with the `question` tool.
2. After the student submits their answers, review each one individually:
   - If correct, confirm and briefly reinforce why.
   - If incorrect, **politely correct** the misunderstanding with a concise
     explanation (provided under each question below).
3. Move to the next section.
4. After all sections, display the total score (e.g. "You got 7 out of 9
   correct.").

**Important:** only present the options listed for each question. Do not provide
the correct answer or explanation text in the `question` tool call — that is for
your own reference when reviewing responses afterwards.

---

## Quiz: Class 1 — Initial OS and Sensor Setup

### Section A: rpi-imager (Flashing Raspberry Pi OS)

Ask these three questions together:

||question 1||

Why does `rpi-imager` require `sudo` to run?

Options:
1. To access the internet for downloading OS images.
2. To write directly to block devices such as SD cards.
3. To modify system configuration files on the host.
4. To run with GPU hardware acceleration.

Answer: 2 — `rpi-imager` needs block-level access to write raw image data to
the SD card, which requires superuser privileges.

||question 2||

Why should you run `lsblk` before starting the imaging process?

Options:
1. To check how much free space is left on your system.
2. To verify which filesystem the SD card is using.
3. To identify the correct target device and avoid overwriting your system disk.
4. To reformat the SD card before writing.

Answer: 3 — `lsblk` lists block devices so you can confirm you are targeting
the SD card, not your computer's internal drive.

||question 3||

Why is it important to pre-configure SSH and Wi-Fi during imaging?

Options:
1. It is required by the Raspberry Pi Foundation's terms of use.
2. It enables headless setup — the Pi boots ready for a remote connection
   without a monitor or keyboard.
3. It speeds up the image-writing process.
4. It encrypts the SD card contents for security.

Answer: 2 — With SSH and Wi-Fi pre-configured, you avoid having to attach a
monitor and keyboard to the Pi after flashing.

---

### Section B: ssh-local (SSH Connectivity)

Ask these four questions together:

||question 4||

Why must the host computer's Ethernet interface be on the `169.254.0.0/16`
subnet when connecting directly to the Pi?

Options:
1. It is the fastest subnet for local connections.
2. Raspberry Pi OS defaults to link-local addressing when no DHCP server is
   available on the wired interface.
3. SSH requires this specific address range.
4. NetworkManager only supports this subnet.

Answer: 2 — Without a DHCP server on the direct Ethernet link, the Pi assigns
itself a link-local address in 169.254.x.x. Your computer must be on the same
subnet to reach it.

||question 5||

What is the purpose of mDNS (Avahi) in this setup?

Options:
1. To encrypt the SSH connection end-to-end.
2. To resolve `.local` hostnames into IP addresses without a DNS server.
3. To speed up file transfers over the wired link.
4. To configure the Ethernet interface automatically.

Answer: 2 — Avahi advertises the Pi's hostname on the local network so you can
use `<hostname>.local` in SSH commands instead of raw IP addresses.

||question 6||

Why is SSH key-based authentication preferred over password authentication?

Options:
1. Raspberry Pi OS does not support password-based SSH.
2. Typing a key file path is faster than typing a password.
3. It is more secure and prevents the teaching assistant agent from ever
   receiving or seeing the student's password.
4. SSH keys are mandatory under university policy.

Answer: 3 — Key-based auth keeps sensitive credentials out of the conversation
transcript. The private key stays on the student's machine; only the public key
is copied to the Pi.

||question 7||

Why use `ed25519` specifically when generating the SSH key?

Options:
1. It is the only key type the Raspberry Pi accepts.
2. It is a modern algorithm that produces compact keys with strong security.
3. It is compatible with every operating system ever released.
4. It was named after a famous educator in the field.

Answer: 2 — Ed25519 offers excellent security in a small key size, making it a
good default for modern SSH setups.

---

### Section C: gpio-dht-setup (DHT11 Sensor)

Ask these four questions together:

||question 8||

Why must GPIO input pins only be exposed to 3.3V logic and never 5V?

Options:
1. 5V signals cause the sensor to return inaccurate readings.
2. The DHT11 sensor only accepts 3.3V.
3. Applying 5V to a GPIO input pin will permanently damage or destroy the
   Raspberry Pi.
4. 5V pins are reserved exclusively for USB power output.

Answer: 3 — The Pi's GPIO pins operate at 3.3V logic. Sending 5V into an input
pin can burn the pin or the entire board. Always double-check wiring before
powering on.

||question 9||

Why is the 10K Ohm pull-up resistor between VCC and DATA essential for the
DHT11?

Options:
1. It amplifies the weak sensor signal.
2. It protects the sensor from voltage spikes and surges.
3. It holds the data line HIGH so the sensor can pull it LOW to transmit bits.
4. It converts the sensor's analog output into a digital signal.

Answer: 3 — Without the pull-up resistor, the data line floats at an undefined
voltage and the sensor cannot reliably signal. The resistor keeps it at a known
HIGH level, and the sensor briefly pulls it LOW to communicate.

||question 10||

Why use `getattr(board, pin_name)` instead of hard-coding the pin?

Options:
1. The Adafruit library requires it for compliance.
2. It allows the GPIO pin to be selected dynamically from a command-line
   argument or configuration string.
3. It runs faster than a direct attribute access.
4. It automatically detects which sensor is connected to which pin.

Answer: 2 — `getattr` resolves a string (like `"D23"` from CLI arguments) into
the corresponding `board.D23` object at runtime, making the script reusable
with different pin assignments.

||question 11||

In the sensor reading script, why is `RuntimeError` caught separately from other
exceptions?

Options:
1. `RuntimeError` means the sensor is permanently broken and must be replaced.
2. Transient read failures (common with the DHT11's timing-sensitive protocol)
   should be skipped, while critical errors such as a wrong pin should abort the
   script.
3. The Adafruit library does not raise `RuntimeError`, so the catch is
   unnecessary.
4. The course rubric requires a separate catch block.

Answer: 2 — The DHT11 occasionally fails to read due to tight timing
requirements. `RuntimeError` catches harmless glitches (skip and retry), while
other exceptions like `ValueError` or `OSError` indicate real problems that
should stop execution.

---

## Quiz: Classes 2–4 — Not yet developed

Classes 2 (Sending Data to the Cloud), 3 (Creating a Simple Web Server), and 4
(Sending Mobile Notifications) are not yet developed. If the student has somehow
indicated completion of one of these, skip the quiz and proceed directly to the
**Conclusion** section.

---

## After the quiz

Display the total score and offer brief encouragement. For any wrong answers,
politely provide the correct answer with a short explanation (included above
under each question). Do not re-ask missed questions.

---

## Conclusion

Congratulate the student on completing the class. Ask if they have any lingering
questions about anything covered in the session.

If there are none, trigger the `submit-report` skill.
