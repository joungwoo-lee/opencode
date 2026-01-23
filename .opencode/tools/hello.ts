import { tool } from "@opencode-ai/plugin";

export default tool({
  description: "Greets the user",
  args: {
    name: tool.schema.string().describe("The name to greet"),
  },
  async execute(args) {
    return `Hello, ${args.name}!`;
  },
});
