#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  McpError,
  ErrorCode,
} from "@modelcontextprotocol/sdk/types.js";

import { handleBuild, buildToolDefinition } from './tools/build.js';
import { handleCreate, createToolDefinition } from './tools/create.js';
import { handleRun, runToolDefinition } from './tools/run.js';
import { handleDeploy, deployToolDefinition } from './tools/deploy.js';
import { handleTemplates, templatesToolDefinition } from './tools/templates.js';
import { handleExamples, examplesToolDefinition } from './tools/examples.js';
import { handleDeviceInfo, deviceInfoToolDefinition } from './tools/device-info.js';

const server = new Server(
  { name: "playdate-mcp-server", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// Register tool list handler
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    buildToolDefinition,
    createToolDefinition,
    runToolDefinition,
    deployToolDefinition,
    templatesToolDefinition,
    examplesToolDefinition,
    deviceInfoToolDefinition,
  ]
}));

// Register tool execution handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case 'playdate_build':
      return { content: [{ type: 'text', text: JSON.stringify(await handleBuild(args || {}), null, 2) }] };
    case 'playdate_create':
      return { content: [{ type: 'text', text: JSON.stringify(await handleCreate(args || {}), null, 2) }] };
    case 'playdate_run':
      return { content: [{ type: 'text', text: JSON.stringify(await handleRun(args || {}), null, 2) }] };
    case 'playdate_deploy':
      return { content: [{ type: 'text', text: JSON.stringify(await handleDeploy(args || {}), null, 2) }] };
    case 'playdate_templates':
      return { content: [{ type: 'text', text: JSON.stringify(await handleTemplates(), null, 2) }] };
    case 'playdate_examples':
      return { content: [{ type: 'text', text: JSON.stringify(await handleExamples(), null, 2) }] };
    case 'playdate_device_info':
      return { content: [{ type: 'text', text: JSON.stringify(await handleDeviceInfo(), null, 2) }] };
    default:
      throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
  }
});

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
