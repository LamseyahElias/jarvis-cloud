#!/usr/bin/env node
/**
 * Install JARVIS Local Tunnel as a Windows background service
 * Run: node install-service.js
 * Requires admin privileges on first install
 */
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const SERVICE_NAME = 'JARVIS-LocalTunnel';
const SERVER_PATH = path.join(__dirname, 'server.js');
const NODE_PATH = process.execPath;
const LOG_DIR = path.join(__dirname, 'logs');

function run(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf-8', timeout: 10000, windowsHide: true }).trim();
  } catch (e) {
    return e.stdout?.trim() || e.message;
  }
}

console.log('═'.repeat(50));
console.log('  JARVIS Local Tunnel — Windows Service Installer');
console.log('═'.repeat(50));

// Ensure logs dir
if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

// Check if running as admin
const isAdmin = run('net session').length > 0 || process.env.USERNAME === 'SYSTEM';
console.log(`\n  Admin: ${isAdmin ? '✓' : '✗ (service install may fail)'}`);

// Check if service already exists
const existing = run(`sc query "${SERVICE_NAME}"`);
const exists = !existing.includes('1060'); // 1060 = service not found

if (exists) {
  console.log(`  Service "${SERVICE_NAME}" already exists.`);
  console.log('  Stopping and removing...');
  run(`sc stop "${SERVICE_NAME}"`);
  run(`sc delete "${SERVICE_NAME}"`);
}

// Create the service
const cmd = [
  'sc create',
  `"${SERVICE_NAME}"`,
  'binPath=',
  `"${NODE_PATH} ${SERVER_PATH}"`,
  'start=',
  'auto',
  'DisplayName=',
  '"JARVIS Local Tunnel — Remote command execution for cloud Hermes"'
].join(' ');

console.log(`\n  Creating service...`);
const result = run(cmd);
console.log(`  ${result}`);

// Set failure recovery
run(`sc failure "${SERVICE_NAME}" reset=60 actions=restart/5000/restart/10000/run/30000`);

// Description
run(`sc description "${SERVICE_NAME}" "JARVIS Local Tunnel — Enables the cloud Hermes agent to execute commands on this Windows machine"`);

// Start the service
console.log(`\n  Starting service...`);
const startResult = run(`sc start "${SERVICE_NAME}"`);
console.log(`  ${startResult}`);

// Verify
setTimeout(() => {
  const status = run(`sc query "${SERVICE_NAME}"`);
  const running = status.includes('RUNNING');
  
  console.log(`\n  Status: ${running ? '✓ RUNNING' : '✗ NOT RUNNING'}`);
  console.log(`  Service name: ${SERVICE_NAME}`);
  console.log(`  Node: ${NODE_PATH}`);
  console.log(`  Server: ${SERVER_PATH}`);
  console.log(`  Logs: ${LOG_DIR}`);
  
  if (running) {
    console.log(`\n  ✅ JARVIS Local Tunnel is running as a Windows service!`);
    console.log(`  It will auto-start on boot.`);
  } else {
    console.log(`\n  ⚠️  Service installed but not running.`);
    console.log(`  Try: sc start "${SERVICE_NAME}"`);
  }
  console.log('═'.repeat(50));
}, 2000);
