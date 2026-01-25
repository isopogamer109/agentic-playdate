import { existsSync } from 'fs';
import { DeviceInfo } from '../types.js';
import { execCommand } from '../utils/exec.js';
import { getPdutilPath } from '../utils/paths.js';

export const deviceInfoToolDefinition = {
  name: 'playdate_device_info',
  description: 'Get status and info of connected Playdate device.',
  inputSchema: {
    type: 'object' as const,
    properties: {},
    required: [] as string[]
  }
};

export async function handleDeviceInfo(): Promise<DeviceInfo> {
  const pdutil = getPdutilPath();

  if (!existsSync(pdutil)) {
    return {
      connected: false,
      error: `pdutil not found at ${pdutil}`
    };
  }

  const result = await execCommand(pdutil, ['info']);

  if (result.exitCode !== 0) {
    return {
      connected: false,
      error: 'No Playdate device found. Ensure device is connected via USB and unlocked.'
    };
  }

  // Parse pdutil info output
  const output = result.stdout;
  let serialNumber: string | undefined;
  let firmwareVersion: string | undefined;

  const serialMatch = output.match(/serial[:\s]+(\S+)/i);
  if (serialMatch) serialNumber = serialMatch[1];

  const versionMatch = output.match(/version[:\s]+(\S+)/i);
  if (versionMatch) firmwareVersion = versionMatch[1];

  return {
    connected: true,
    serialNumber,
    firmwareVersion
  };
}
