import { readdirSync, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { TemplateInfo } from '../types.js';
import { getTemplatesDir } from '../utils/paths.js';

export const templatesToolDefinition = {
  name: 'playdate_templates',
  description: 'List available Playdate project templates.',
  inputSchema: {
    type: 'object' as const,
    properties: {},
    required: [] as string[]
  }
};

export async function handleTemplates(): Promise<TemplateInfo[]> {
  const templatesDir = getTemplatesDir();
  const templates: TemplateInfo[] = [];

  if (!existsSync(templatesDir)) {
    return templates;
  }

  const entries = readdirSync(templatesDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;

    const templatePath = join(templatesDir, entry.name);
    let description = '';

    // Extract description from main.lua comment header
    const mainLuaPath = join(templatePath, 'source', 'main.lua');
    if (existsSync(mainLuaPath)) {
      const content = readFileSync(mainLuaPath, 'utf-8');
      const match = content.match(/^--\[\[\s*\n\s*(.+?)\n/);
      if (match) {
        description = match[1].trim();
      }
    }

    templates.push({
      name: entry.name,
      description,
      path: templatePath
    });
  }

  return templates;
}
