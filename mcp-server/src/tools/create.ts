import { existsSync, cpSync, readFileSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { CreateResult } from '../types.js';
import { getTemplatesDir } from '../utils/paths.js';

export const createToolDefinition = {
  name: 'playdate_create',
  description: 'Create a new Playdate project from a template.',
  inputSchema: {
    type: 'object' as const,
    properties: {
      name: {
        type: 'string',
        description: 'Project name (will be created as a directory)'
      },
      template: {
        type: 'string',
        description: 'Template to use (basic, crank-game, sprite-based). Defaults to basic.'
      },
      outputDir: {
        type: 'string',
        description: 'Parent directory for the project (defaults to cwd)'
      }
    },
    required: ['name'] as string[]
  }
};

export async function handleCreate(args: Record<string, unknown>): Promise<CreateResult> {
  const name = args.name as string;
  const template = (args.template as string) || 'basic';
  const outputDir = resolve((args.outputDir as string) || process.cwd());
  const projectPath = join(outputDir, name);
  const templatePath = join(getTemplatesDir(), template);

  if (existsSync(projectPath)) {
    return { success: false, projectPath: '', template, error: `Directory already exists: ${projectPath}` };
  }

  if (!existsSync(templatePath)) {
    return { success: false, projectPath: '', template, error: `Template not found: ${template}` };
  }

  try {
    // Copy template
    cpSync(templatePath, projectPath, { recursive: true });

    // Update pdxinfo with project name
    const pdxinfoPath = join(projectPath, 'source', 'pdxinfo');
    if (existsSync(pdxinfoPath)) {
      let content = readFileSync(pdxinfoPath, 'utf-8');
      content = content.replace(/TemplateName/g, name);
      const safeName = name.toLowerCase().replace(/[^a-z0-9]/g, '');
      content = content.replace(/templatename/g, safeName);
      writeFileSync(pdxinfoPath, content);
    }

    return { success: true, projectPath, template };
  } catch (err) {
    return { success: false, projectPath: '', template, error: String(err) };
  }
}
