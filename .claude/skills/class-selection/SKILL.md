---
name: class-selection
description: Activated when the student asks what classes are available or needs to pick a class. Presents available IoT classes and routes to the selected one.
compatibility: claude
---

## What I do

Present the available IoT classes to the student as numbered options and route
them to the appropriate skill based on their choice.

## When to use me

When the student asks what classes are available, which classes they can take,
or when the agent needs to present class options for the student to pick from.

---

## Class selection

Present the following classes as numbered options and ask the student which one
they would like to undertake:

1. **Initial OS and Sensor Setup** — Flash Raspberry Pi OS, establish SSH
   connectivity, and read data from a DHT11 temperature/humidity sensor via
   GPIO.
2. **Sending Data to the Cloud** — Send sensor readings to a cloud service for
   storage and visualization.
3. **Creating a Simple Web Server** — Host a lightweight web server on the
   Raspberry Pi to serve sensor data.
4. **Sending Mobile Notifications** — Trigger push notifications to a mobile
   device based on sensor thresholds.

## Routing

### Class 1: Initial OS and Sensor Setup

Call the skill `rpi-imager`, going through its contents step by step.

### Classes 2–4: Not yet developed

Inform the student that the selected class is **not yet developed** and suggest
they try an available class instead. The only available class at this time is:

1. **Initial OS and Sensor Setup**

Encourage them to start with Class 1 as it lays the foundation for future
classes.
