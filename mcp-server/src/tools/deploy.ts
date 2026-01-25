import { existsSync } from 'fs';
import { resolve, join } from 'path';
import { DeployResult } from '../types.js';
import { execCommand } from '../utils/exec.js';
import { getPdutilPath } from '../utils/paths.js';

export const deployToolDefinition = {
  name: 'playdate_deploy',
  description: 'Install a .pdx to a connected Playdate device via USB.',
  inputSchema: {
    type: 'object' as const,
    properties: {
      pdxPath: {
        type: 'string',
        description: 'Path to .pdx file (defaults to output.pdx in cwd)'
      }
    },
    required: [] as string[]
  }
};

export async function handleDeploy(args: Record<string, unknown>): Promise<DeployResult> {
  const pdxPath = resolve((args.pdxPath as string) || join(process.cwd(), 'output.pdx'));
  const pdutil = getPdutilPath();

  if (!existsSync(pdxPath)) {
    return { success: false, error: `PDX not found: ${pdxPath}` };
  }

  if (!existsSync(pdutil)) {
    return { success: false, error: `pdutil not found at ${pdutil}` };
  }

  // Check device connection first
  const infoResult = await execCommand(pdutil, ['info']);
  if (infoResult.exitCode !== 0) {
    return {
      success: false,
      error: 'No Playdate device found. Ensure device is connected via USB and unlocked.'
    };
  }

  // Install to device
  const installResult = await execCommand(pdutil, ['install', pdxPath]);

  return {
    success: installResult.exitCode === 0,
    error: installResult.exitCode !== 0 ? installResult.stderr || 'Installation failed' : undefined
  };
}
