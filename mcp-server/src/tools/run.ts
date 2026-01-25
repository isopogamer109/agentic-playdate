import { existsSync } from 'fs';
import { join, resolve } from 'path';
import { RunResult } from '../types.js';
import { execCommand } from '../utils/exec.js';
import { getSimulatorPath } from '../utils/paths.js';

export const runToolDefinition = {
  name: 'playdate_run',
  description: 'Launch the Playdate Simulator with a .pdx file.',
  inputSchema: {
    type: 'object' as const,
    properties: {
      pdxPath: {
        type: 'string',
        description: 'Path to .pdx file/directory (defaults to output.pdx in cwd)'
      }
    },
    required: [] as string[]
  }
};

export async function handleRun(args: Record<string, unknown>): Promise<RunResult> {
  const pdxPath = resolve((args.pdxPath as string) || join(process.cwd(), 'output.pdx'));
  const simulator = getSimulatorPath();

  if (!existsSync(pdxPath)) {
    return { success: false, simulatorLaunched: false, error: `PDX not found: ${pdxPath}` };
  }

  if (!existsSync(simulator)) {
    return { success: false, simulatorLaunched: false, error: `Playdate Simulator not found at ${simulator}` };
  }

  // Use 'open -a' on macOS to launch the simulator
  const result = await execCommand('open', ['-a', simulator, pdxPath]);

  return {
    success: result.exitCode === 0,
    simulatorLaunched: result.exitCode === 0,
    error: result.exitCode !== 0 ? result.stderr : undefined
  };
}
