import { CompileError } from '../types.js';

/**
 * Parse pdc compiler output into structured errors/warnings
 *
 * pdc error format: "source/main.lua:23: error message here"
 */
export function parsePdcOutput(output: string): { errors: CompileError[], warnings: CompileError[] } {
  const errors: CompileError[] = [];
  const warnings: CompileError[] = [];

  const lines = output.split('\n');
  const errorRegex = /^(.+):(\d+):\s+(.+)$/;

  for (const line of lines) {
    const match = line.match(errorRegex);
    if (match) {
      const [, file, lineNum, message] = match;
      const entry: CompileError = {
        file,
        line: parseInt(lineNum, 10),
        message: message.trim(),
        severity: message.toLowerCase().includes('warning') ? 'warning' : 'error'
      };

      if (entry.severity === 'warning') {
        warnings.push(entry);
      } else {
        errors.push(entry);
      }
    }
  }

  return { errors, warnings };
}
