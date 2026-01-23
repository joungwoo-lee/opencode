import { tool } from "@opencode-ai/plugin";
import { join } from "node:path";

export default tool({
  description: "Greets the user by calling a Python script",
  args: {
    name: tool.schema.string().describe("The name to greet"),
  },
  async execute(args) {
    // Dynamically resolve the path to greet.py relative to the current file
    const pythonScriptPath = join(import.meta.dir, "greet.py");

    const result = await Bun.$`python3 ${pythonScriptPath} ${args.name}`.text();
    return result.trim();
  },
});
