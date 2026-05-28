import { tool } from "@opencode-ai/plugin"
import path from "path"

export default tool({
  description:
    "Submit a class session report to the report server. " +
    "Sends a Markdown transcript file with metadata to the report server.",
  args: {
    discipline: tool.schema
      .string()
      .describe(
        "Discipline slug: 'internet-of-things' or 'embedded-systems'"
      ),
    concluded: tool.schema
      .boolean()
      .describe("Whether the class session was concluded"),
    transcript_file: tool.schema
      .string()
      .describe("Path to the Markdown transcript file (e.g. .reports/iot-2026-05-28.md)"),
    server_url: tool.schema
      .string()
      .describe("Report server URL (e.g. https://xxx.trycloudflare.com)"),
    agent: tool.schema
      .string()
      .describe("Name of the agent (e.g. Learn)"),
    model: tool.schema
      .string()
      .describe("Model identifier (e.g. deepseek-v4-flash-free)"),
    session_slug: tool.schema
      .string()
      .describe("Descriptive slug with random suffix for uniqueness (e.g. iot-class1-dG9rZW4)"),
    reason: tool.schema
      .string()
      .optional()
      .describe("Reason if the session was not concluded"),
    summary: tool.schema
      .string()
      .optional()
      .describe("Optional summary of the session"),
  },
  async execute(args, context) {
    const scriptsDir = path.join(context.worktree, ".opencode", "scripts")
    const script = path.join(scriptsDir, "submit-report.sh")

    const transcriptPath = path.isAbsolute(args.transcript_file)
      ? args.transcript_file
      : path.join(context.worktree, args.transcript_file)

    const scriptArgs = [
      args.discipline,
      String(args.concluded),
      transcriptPath,
      args.server_url,
      args.agent,
      args.model,
      args.session_slug,
    ]

    if (args.reason) {
      scriptArgs.push(args.reason)
    } else {
      scriptArgs.push("")
    }

    scriptArgs.push("--async")

    if (args.summary) {
      scriptArgs.push("--summary", args.summary)
    }

    try {
      const result = await Bun.$`bash ${script} ${scriptArgs}`.text()
      return result.trim()
    } catch (err) {
      return `Error submitting report: ${err}`
    }
  },
})