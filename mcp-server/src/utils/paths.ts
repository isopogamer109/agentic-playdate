import { homedir } from 'os';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

export function getSDKPath(): string {
  return process.env.PLAYDATE_SDK_PATH || join(homedir(), 'Developer', 'PlaydateSDK');
}

export function getDevRoot(): string {
  if (process.env.PLAYDATE_DEV_ROOT) {
    return process.env.PLAYDATE_DEV_ROOT;
  }
  // MCP server lives in playdate-dev/mcp-server/build, so go up to playdate-dev
  const __dirname = dirname(fileURLToPath(import.meta.url));
  return join(__dirname, '..', '..');
}

export function getTemplatesDir(): string {
  return join(getDevRoot(), 'templates');
}

export function getExamplesDir(): string {
  return join(getDevRoot(), 'examples');
}

export function getPdcPath(): string {
  return join(getSDKPath(), 'bin', 'pdc');
}

export function getPdutilPath(): string {
  return join(getSDKPath(), 'bin', 'pdutil');
}

export function getSimulatorPath(): string {
  return join(getSDKPath(), 'Playdate Simulator.app');
}
