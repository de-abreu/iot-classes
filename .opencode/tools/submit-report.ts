import { tool } from "@opencode-ai/plugin"
import path from "path"

export default tool({
  description:
    "Submit a class session report to the report server. " +
    "Extracts the transcript from the current session and sends it asynchronously. " +
    "The report is stored as a Markdown file organized by discipline and year.",
  args: {
    discipline: tool.schema
      .string()
      .describe(
        "Discipline slug: 'internet-of-things' or 'embedded-systems'"
      ),
    concluded: tool.schema
      .boolean()
      .describe("Whether the class session was concluded"),
    reason: tool.schema
      .string()
      .optional()
      .describe("Reason if the session was not concluded"),
    summary: tool.schema
      .string()
      .optional()
      .describe("Optional summary of the session"),
    server_url: tool.schema
      .string()
      .describe("Report server URL (e.g. https://xxx.trycloudflare.com)"),
  },
  async execute(args, context) {
    const scriptsDir = path.join(context.worktree, ".opencode", "scripts")
    const script = path.join(scriptsDir, "submit-report.sh")

    const scriptArgs = [
      context.sessionID,
      args.discipline,
      String(args.concluded),
      args.reason || "",
      args.server_url,
      "--async",
    ]

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