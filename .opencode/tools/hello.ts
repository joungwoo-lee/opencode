import { tool } from "@opencode-ai/plugin";

export default tool({
  description: "Greets the user by calling a Python script",
  args: {
    name: tool.schema.string().describe("The name to greet"),
  },
  async execute(args) {
    const result = await Bun.$`python3 .opencode/tools/hello.py ${args.name}`.text();
    return result.trim();
  },
});
