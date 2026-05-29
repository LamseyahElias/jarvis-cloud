const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { execSync, exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 4899;
const AUTH_TOKEN = process.env.JARVIS_TUNNEL_TOKEN || crypto.randomBytes(32).toString('hex');

// ── Middleware ──────────────────────────────────────────────────────
app.use(cors());
app.use(morgan('[:date[iso]] :method :url :status :response-time ms'));
app.use(express.json({ limit: '10mb' }));
app.use(express.text({ limit: '10mb' }));

// ── Authentication ──────────────────────────────────────────────────
function authenticate(req, res, next) {
  const token = req.headers['authorization']?.replace('Bearer ', '');
  if (!token || token !== AUTH_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

// Print auth token on startup
console.log(`\n🔐 JARVIS Local Tunnel Daemon`);
console.log(`   Auth Token: ${AUTH_TOKEN}`);
console.log(`   Save this — you'll add it to Railway as TUNNEL_AUTH_TOKEN\n`);

// ── Health check (no auth required) ────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'alive',
    hostname: os.hostname(),
    platform: os.platform(),
    uptime: Math.floor(process.uptime()),
    arch: os.arch(),
    cpus: os.cpus().length,
    memory: {
      free: Math.round(os.freemem() / 1024 / 1024),
      total: Math.round(os.totalmem() / 1024 / 1024)
    }
  });
});

// ── Execute command ─────────────────────────────────────────────────
app.post('/exec', authenticate, (req, res) => {
  const { command, cwd, timeout = 60000 } = req.body;
  
  if (!command || typeof command !== 'string') {
    return res.status(400).json({ error: 'command required' });
  }

  const safeCwd = cwd || process.env.USERPROFILE || 'C:\\';
  
  console.log(`  ▶ exec: ${command.substring(0, 100)}${command.length > 100 ? '...' : ''}`);

  try {
    const output = execSync(command, {
      cwd: safeCwd,
      timeout,
      maxBuffer: 10 * 1024 * 1024, // 10MB
      shell: 'cmd.exe',
      encoding: 'utf-8',
      windowsHide: true
    });
    
    res.json({
      success: true,
      exit_code: 0,
      stdout: output,
      stderr: '',
      cwd: safeCwd
    });
  } catch (error) {
    res.json({
      success: error.status === 0,
      exit_code: error.status || -1,
      stdout: error.stdout || '',
      stderr: error.stderr || error.message,
      cwd: safeCwd
    });
  }
});

// ── PowerShell exec ────────────────────────────────────────────────
app.post('/exec/powershell', authenticate, (req, res) => {
  const { command, timeout = 120000 } = req.body;
  
  if (!command) {
    return res.status(400).json({ error: 'command required' });
  }

  console.log(`  ▶ powershell: ${command.substring(0, 100)}${command.length > 100 ? '...' : ''}`);

  try {
    const output = execSync(`powershell -NoProfile -Command "${command.replace(/"/g, '\\"')}"`, {
      timeout,
      maxBuffer: 10 * 1024 * 1024,
      shell: 'cmd.exe',
      encoding: 'utf-8',
      windowsHide: true
    });
    
    res.json({ success: true, exit_code: 0, stdout: output, stderr: '' });
  } catch (error) {
    res.json({
      success: error.status === 0,
      exit_code: error.status || -1,
      stdout: error.stdout || '',
      stderr: error.stderr || error.message
    });
  }
});

// ── Read file ──────────────────────────────────────────────────────
app.post('/read-file', authenticate, (req, res) => {
  const { filepath, offset = 0, limit = 500 } = req.body;
  
  if (!filepath) {
    return res.status(400).json({ error: 'filepath required' });
  }

  try {
    const absPath = path.resolve(filepath);
    if (!fs.existsSync(absPath)) {
      return res.status(404).json({ error: 'File not found', path: absPath });
    }
    
    const content = fs.readFileSync(absPath, 'utf-8');
    const lines = content.split('\n');
    const totalLines = lines.length;
    
    const start = offset > 0 ? offset - 1 : 0;
    const selected = lines.slice(start, start + limit);
    
    res.json({
      path: absPath,
      total_lines: totalLines,
      lines: selected,
      offset: start + 1,
      limit
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Write file ─────────────────────────────────────────────────────
app.post('/write-file', authenticate, (req, res) => {
  const { filepath, content } = req.body;
  
  if (!filepath || content === undefined) {
    return res.status(400).json({ error: 'filepath and content required' });
  }

  try {
    const absPath = path.resolve(filepath);
    const dir = path.dirname(absPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    fs.writeFileSync(absPath, content, 'utf-8');
    res.json({ success: true, path: absPath, bytes: Buffer.byteLength(content, 'utf-8') });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── List directory ──────────────────────────────────────────────────
app.post('/ls', authenticate, (req, res) => {
  const { dirpath = process.env.USERPROFILE || 'C:\\' } = req.body;

  try {
    const absPath = path.resolve(dirpath);
    const entries = fs.readdirSync(absPath, { withFileTypes: true });
    
    const files = entries.map(e => ({
      name: e.name,
      is_dir: e.isDirectory(),
      size: e.isFile() ? fs.statSync(path.join(absPath, e.name)).size : null,
      modified: e.isFile() ? fs.statSync(path.join(absPath, e.name)).mtime : null
    }));
    
    res.json({ path: absPath, files });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Get system info ────────────────────────────────────────────────
app.get('/system', authenticate, (req, res) => {
  const drives = [];
  try {
    const df = execSync('wmic logicaldisk get name,size,freespace /format:csv', {
      encoding: 'utf-8', timeout: 5000, windowsHide: true
    });
    df.split('\n').slice(1).forEach(line => {
      const parts = line.trim().split(',');
      if (parts.length >= 3 && parts[1]) {
        drives.push({
          drive: parts[1],
          free: parseInt(parts[2]) ? Math.round(parseInt(parts[2]) / 1024 / 1024 / 1024) : null,
          total: parseInt(parts[3]) ? Math.round(parseInt(parts[3]) / 1024 / 1024 / 1024) : null
        });
      }
    });
  } catch (e) {}

  res.json({
    hostname: os.hostname(),
    platform: os.platform(),
    release: os.release(),
    uptime: Math.floor(os.uptime()),
    cpus: os.cpus().length,
    memory: {
      free: Math.round(os.freemem() / 1024 / 1024),
      total: Math.round(os.totalmem() / 1024 / 1024)
    },
    drives,
    user: process.env.USERNAME,
    userprofile: process.env.USERPROFILE
  });
});

// ── Start server ────────────────────────────────────────────────────
app.listen(PORT, '0.0.0.0', () => {
  console.log(`   Server running on http://0.0.0.0:${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/health`);
  console.log(`   Platform: ${os.platform()} ${os.release()}`);
  console.log(`   Hostname: ${os.hostname()}`);
  console.log('──────────────────────────────────────────────────\n');
});
