---
name: submit-report
description: Activated when a class session ends or when the student explicitly asks to send a report. Writes a de-identified transcript to .reports/ and submits it to the report server using the submit_report custom tool.
compatibility: claude
---

## What I do

Submit a class session report to the report server. The report contains a
de-identified transcript of the session, plus metadata such as date, discipline,
and whether the class was concluded.

## When to use me

### Automatic: end of class

When the student has completed all steps of a class successfully, or the session
is naturally wrapping up (e.g., the student says "that's all for today", "I'm
done", or similar closing signals).

### Manual: student request

When the student explicitly asks to send a report, submit a report, or get help
from the human TA. This often means they are struggling and want human
assistance before the class is over.

## De-identification

Before writing the transcript, **remove or redact** personally identifiable
information. This includes:

- Student names, emails, and student ID numbers
- IP addresses, SSH hostnames, and MAC addresses specific to the student
- Any other information that could identify the individual

Replace redacted content with `[REDACTED]`. General content, code snippets,
error messages, and sensor readings do not need redaction.

## How to submit

### Step 1: Write the transcript

1. Create the `.reports/` directory if it does not exist:

   ```bash
   mkdir -p .reports
   ```

2. Write a **Markdown transcript** of the session to
   `.reports/<discipline>-<date>.md` (e.g.
   `.reports/internet-of-things-2026-05-28.md`).

   The transcript should follow this structure:

   ```markdown
   # Class Report: <discipline>

   - **Date:** <date>
   - **Concluded:** <true or false>
   - **Reason:** <reason if not concluded, omit if concluded>
   - **Summary:** <optional brief summary of the session>

   ---

   ## Transcript

   ### User

   <paraphrased user message>

   ### Agent

   <paraphrased assistant response>

   ### User

   <paraphrased next user message>

   ...
   ```

### Step 2: Determine metadata

Determine the following:

- `discipline`: `internet-of-things` for Class 1 (Initial OS and Sensor Setup).
  If the discipline is ambiguous, ask the student.
- `concluded`: `true` if all steps of the class were completed, `false`
  otherwise.
- `reason`: if `concluded` is `false`, ask the student for a brief reason (e.g.
  "ran out of time", "need human TA help with SSH").
- `session_slug`: a descriptive slug for the session with a random suffix to
  avoid collisions. Generate the random suffix by running:

  ```bash
  python3 -c "import secrets; print(secrets.token_urlsafe(4))"
  ```

  Then compose the slug as `<descriptive-prefix>-<random-suffix>`, e.g.
  `iot-class1-initial-setup-dG9rZW4`. Use a short descriptive prefix that
  reflects the class content.

### Step 3: Call the submit_report tool

Call the `submit_report` tool with:

- `discipline`: one of `internet-of-things` or `embedded-systems`
- `concluded`: boolean
- `transcript_file`: the path to the Markdown file written in Step 1 (e.g.
  `.reports/internet-of-things-2026-05-28.md`)
- `server_url`: the value of `REPORT_SERVER_URL` from `.env`
- `agent`: your own agent name (e.g. `Learn`)
- `model`: the model you are running on (e.g. `deepseek-v4-flash-free`)
- `session_slug`: the descriptive slug with random suffix generated in Step 2
- `reason`: string or omitted
- `summary`: string or omitted

### Step 4: Inform the student

- On success: "Your class report has been submitted. Thank you!"
- On failure: "There was an issue submitting your report. The error was:
  <error message>."
- If prerequisites missing: "Your report could not be sent because the `.env`
  file is not configured. No action needed — this just means the report won't be
  stored on the server."

## After submission

Activate the `class-selection` skill to offer the student their next class.
