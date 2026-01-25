import { existsSync } from 'fs';
import { join, resolve } from 'path';
import { BuildResult } from '../types.js';
import { execCommand } from '../utils/exec.js';
import { getPdcPath } from '../utils/paths.js';
import { parsePdcOutput } from '../utils/pdc-parser.js';

export const buildToolDefinition = {
  name: 'playdate_build',
  description: 'Compile Playdate Lua source to .pdx bundle. Parses compiler errors into structured output.',
  inputSchema: {
    type: 'object' as const,
    properties: {
      sourceDir: {
        type: 'string',
        description: 'Path to source directory (defaults to ./source or ./Source in projectDir)'
      },
      outputPath: {
        type: 'string',
        description: 'Output .pdx path (defaults to output.pdx in projectDir)'
      },
      projectDir: {
        type: 'string',
        description: 'Project root directory (defaults to current working directory)'
      }
    },
    required: [] as string[]
  }
};

export async function handleBuild(args: Record<string, unknown>): Promise<BuildResult> {
  const projectDir = resolve((args.projectDir as string) || process.cwd());

  // Find source directory
  let sourceDir = args.sourceDir as string | undefined;
  if (!sourceDir) {
    for (const candidate of ['source', 'Source', 'src']) {
      const path = join(projectDir, candidate);
      if (existsSync(path)) {
        sourceDir = path;
        break;
      }
    }
  } else {
    sourceDir = resolve(projectDir, sourceDir);
  }

  if (!sourceDir || !existsSync(sourceDir)) {
    return {
      success: false,
      outputPath: '',
      errors: [{ file: '', line: 0, message: 'No source directory found (looking for source/, Source/, or src/)', severity: 'error' }],
      warnings: []
    };
  }

  const outputPath = resolve(projectDir, (args.outputPath as string) || 'output.pdx');
  const pdc = getPdcPath();

  if (!existsSync(pdc)) {
    return {
      success: false,
      outputPath: '',
      errors: [{ file: '', line: 0, message: `pdc compiler not found at ${pdc}`, severity: 'error' }],
      warnings: []
    };
  }

  const result = await execCommand(pdc, [sourceDir, outputPath], projectDir);
  const { errors, warnings } = parsePdcOutput(result.stderr + result.stdout);

  return {
    success: result.exitCode === 0,
    outputPath: result.exitCode === 0 ? outputPath : '',
    errors,
    warnings
  };
}
