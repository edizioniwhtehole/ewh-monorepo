#!/usr/bin/env node
/**
 * Terminal Proxy Server - Runs on HOST machine
 * Accepts commands from Docker containers and executes them on the host
 *
 * Usage: node scripts/terminal-proxy.js
 */

const http = require('http');
const { exec } = require('child_process');
const { promisify } = require('util');

const execPromise = promisify(exec);

const PORT = 3299;
const MAX_TIMEOUT = 30000;

// Allowed commands whitelist (for security)
const ALLOWED_COMMANDS = [
  'git',
  'docker',
  'docker-compose',
  'npm',
  'pnpm',
  'node',
  'psql',
  '/opt/homebrew/bin/psql',
  'pg_dump',
  'lsof',
  'kill',
  'ls',
  'pwd',
  'cat',
  'echo',
  'curl',
  'wget',
  'grep',
  'find',
  './scripts/start-dev.sh'
];

function isCommandAllowed(command) {
  const firstWord = command.trim().split(/\s+/)[0];
  return ALLOWED_COMMANDS.some(allowed => firstWord.startsWith(allowed));
}

const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', async () => {
    try {
      const { command, workingDirectory } = JSON.parse(body);

      if (!command || typeof command !== 'string') {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Command is required' }));
        return;
      }

      // Security check
      if (!isCommandAllowed(command)) {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          error: 'Command not allowed',
          message: 'For security reasons, only whitelisted commands are allowed.',
          allowed: ALLOWED_COMMANDS
        }));
        return;
      }

      const startTime = Date.now();

      try {
        const options = {
          timeout: MAX_TIMEOUT,
          maxBuffer: 1024 * 1024 * 10, // 10MB
          shell: true,
          env: {
            ...process.env,
            FORCE_COLOR: '0'
          }
        };

        if (workingDirectory) {
          options.cwd = workingDirectory;
        }

        const { stdout, stderr } = await execPromise(command, options);
        const executionTime = Date.now() - startTime;

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          command,
          stdout: stdout || '',
          stderr: stderr || '',
          executionTime,
          workingDirectory: options.cwd || process.cwd(),
          executionMode: 'host-proxy'
        }));

      } catch (error) {
        const executionTime = Date.now() - startTime;

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          command,
          stdout: error.stdout || '',
          stderr: error.stderr || error.message,
          exitCode: error.code,
          executionTime,
          workingDirectory: workingDirectory || process.cwd(),
          executionMode: 'host-proxy'
        }));
      }

    } catch (error) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid JSON' }));
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Terminal Proxy Server running on port ${PORT}`);
  console.log(`   Listening on http://localhost:${PORT}`);
  console.log(`   Allowed commands: ${ALLOWED_COMMANDS.join(', ')}`);
  console.log(`\n   Press Ctrl+C to stop\n`);
});
