import { readdirSync, existsSync } from 'fs';
import { join } from 'path';
import { ExampleInfo } from '../types.js';
import { getExamplesDir } from '../utils/paths.js';

export const examplesToolDefinition = {
  name: 'playdate_examples',
  description: 'List available Playdate example projects.',
  inputSchema: {
    type: 'object' as const,
    properties: {},
    required: [] as string[]
  }
};

export async function handleExamples(): Promise<ExampleInfo[]> {
  const examplesDir = getExamplesDir();
  const examples: ExampleInfo[] = [];

  if (!existsSync(examplesDir)) {
    return examples;
  }

  const entries = readdirSync(examplesDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const examplePath = join(examplesDir, entry.name);
    const hasBuiltPdx = existsSync(join(examplePath, 'output.pdx'));

    examples.push({
      name: entry.name,
      path: examplePath,
      hasBuiltPdx
    });
  }

  return examples;
}
