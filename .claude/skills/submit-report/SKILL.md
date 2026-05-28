---
name: submit-report
description: Activated when a class session ends or when the student explicitly asks to send a report. Submits the session transcript and metadata to the report server using the submit_report custom tool.
compatibility: claude
---

## What I do

Submit a class session report to the report server. The report contains a
transcript of the session (with personally identifiable information removed),
plus metadata such as date, discipline, and whether the class was concluded.

## When to use me

### Automatic: end of class

When the student has completed all steps of a class successfully, or the session
is naturally wrapping up (e.g., the student says "that's all for today", "I'm
done", or similar closing signals).

### Manual: student request

When the student explicitly asks to send a report, submit a report, or get help
from the human TA. This often means they are struggling and want human
assistance before the class is over.

## Prerequisites

Before attempting to submit a report, verify that `.env` exists in the project
root (`/home/abreu/Public/UPT/IoT/project/.env`) and contains both `AUTH_TOKEN`
and `REPORT_SERVER_URL`. If the file is empty or missing either value, do not
attempt submission — just inform the student that the report could not be sent
because consent was not configured.

## De-identification

Before submitting, the agent **must** remove or redact personally identifiable
information from the transcript. This includes:

- Student names, emails, and student ID numbers
- IP addresses, SSH hostnames, and MAC addresses specific to the student
- Any other information that could identify the individual

Replace redacted content with `[REDACTED]`. General content, code snippets,
error messages, and sensor readings do not need redaction.

## How to submit

1. Determine the discipline for the current class:
   - Class 1 (Initial OS and Sensor Setup) → `internet-of-things`
   - Classes 2–4 → `internet-of-things`
   - If the discipline is ambiguous, ask the student.

2. Determine `concluded`:
   - `true` if all steps of the class were completed
   - `false` if the student is sending the report early or the class was
     interrupted

3. If `concluded` is `false`, ask the student for a brief `reason` (e.g., "ran
   out of time", "need human TA help with SSH", etc.)

4. Call the `submit_report` tool with:
   - `discipline`: one of `internet-of-things` or `embedded-systems`
   - `concluded`: boolean
   - `reason`: string or omitted
   - `summary`: string or omitted
   - `server_url`: the value of `REPORT_SERVER_URL` from `.env`

5. Inform the student of the result:
   - On success: "Your class report has been submitted. Thank you!"
   - On failure: "There was an issue submitting your report. The error was:
     <error message>."
   - If prerequisites missing: "Your report could not be sent because the `.env`
     file is not configured. No action needed — this just means the report won't
     be stored on the server."

## After submission

Activate the `class-selection` skill to offer the student their next class.
