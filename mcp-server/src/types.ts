export interface BuildResult {
  success: boolean;
  outputPath: string;
  errors: CompileError[];
  warnings: CompileError[];
}

export interface CompileError {
  file: string;
  line: number;
  message: string;
  severity: 'error' | 'warning';
}

export interface TemplateInfo {
  name: string;
  description: string;
  path: string;
}

export interface ExampleInfo {
  name: string;
  path: string;
  hasBuiltPdx: boolean;
}

export interface DeviceInfo {
  connected: boolean;
  serialNumber?: string;
  firmwareVersion?: string;
  error?: string;
}

export interface CreateResult {
  success: boolean;
  projectPath: string;
  template: string;
  error?: string;
}

export interface RunResult {
  success: boolean;
  simulatorLaunched: boolean;
  error?: string;
}

export interface DeployResult {
  success: boolean;
  error?: string;
}
