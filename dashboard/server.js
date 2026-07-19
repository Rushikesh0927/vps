const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const jwt = require('jsonwebtoken');
const Docker = require('dockerode');
const mcping = require('mcping-js');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { execFile } = require('child_process');

const app = express();
const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// Configuration
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'rushiadmin';
const FRIENDS_PIN = process.env.FRIENDS_PIN || '1928';
const JWT_SECRET = process.env.JWT_SECRET || 'supersecrethydrakey';
const DATA_DIR = process.env.DATA_DIR || '/data';
const SERVER_IP = process.env.SERVER_IP || 'rushiserver.duckdns.org';
const DISPLAY_IP = process.env.DISPLAY_IP || SERVER_IP;
const BEDROCK_IP = process.env.BEDROCK_IP || null;
const RCLONE_CONFIG = process.env.RCLONE_CONFIG || '/root/.config/rclone/rclone.conf';
const GDRIVE_FOLDER = 'minecraft_backups';

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(cookieParser());
app.use(express.static('public'));

// ---------------------------------------------------------
// Authentication Middleware
// ---------------------------------------------------------
function authenticateAdmin(req, res, next) {
    const token = req.cookies.admin_token;
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
        jwt.verify(token, JWT_SECRET);
        next();
    } catch (e) {
        res.status(401).json({ error: 'Invalid token' });
    }
}

function authenticateAny(req, res, next) {
    const token = req.cookies.admin_token || req.cookies.friend_token;
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
        jwt.verify(token, JWT_SECRET);
        next();
    } catch (e) {
        res.status(401).json({ error: 'Invalid token' });
    }
}

// Login with admin password
app.post('/api/login/admin', (req, res) => {
    const { password } = req.body;
    if (password === ADMIN_PASSWORD) {
        const token = jwt.sign({ role: 'admin' }, JWT_SECRET, { expiresIn: '24h' });
        res.cookie('admin_token', token, { httpOnly: true, maxAge: 24 * 60 * 60 * 1000 });
        return res.json({ success: true, role: 'admin' });
    }
    res.status(401).json({ error: 'Incorrect password' });
});

// Login with friend PIN
app.post('/api/login/friend', (req, res) => {
    const { pin } = req.body;
    if (pin === FRIENDS_PIN) {
        const token = jwt.sign({ role: 'friend' }, JWT_SECRET, { expiresIn: '24h' });
        res.cookie('friend_token', token, { httpOnly: true, maxAge: 24 * 60 * 60 * 1000 });
        return res.json({ success: true, role: 'friend' });
    }
    res.status(401).json({ error: 'Incorrect PIN' });
});

// Check auth status
app.get('/api/auth', (req, res) => {
    const adminToken = req.cookies.admin_token;
    const friendToken = req.cookies.friend_token;
    if (adminToken) {
        try { jwt.verify(adminToken, JWT_SECRET); return res.json({ role: 'admin' }); } catch (e) {}
    }
    if (friendToken) {
        try { jwt.verify(friendToken, JWT_SECRET); return res.json({ role: 'friend' }); } catch (e) {}
    }
    res.json({ role: null });
});

app.post('/api/logout', (req, res) => {
    res.clearCookie('admin_token');
    res.clearCookie('friend_token');
    res.json({ success: true });
});

// ---------------------------------------------------------
// Status API (Authenticated)
// ---------------------------------------------------------
app.get('/api/status', authenticateAny, async (req, res) => {
    try {
        const container = docker.getContainer('minecraft');
        const info = await container.inspect();
        const isRunning = info.State.Running;
        const uptime = isRunning ? info.State.StartedAt : null;

        if (!isRunning) {
            return res.json({ status: 'offline', players: 0, maxPlayers: 20, playerList: [], uptime: null, serverIp: DISPLAY_IP, bedrockIp: BEDROCK_IP });
        }

        const server = new mcping.MinecraftServer(SERVER_IP, 25565);
        server.ping(3000, 767, (err, pingRes) => {
            if (err) {
                return res.json({ status: 'starting', players: 0, maxPlayers: 20, playerList: [], uptime, serverIp: DISPLAY_IP, bedrockIp: BEDROCK_IP });
            }
            const playerList = (pingRes.players.sample || []).map(p => p.name);
            res.json({
                status: 'online',
                players: pingRes.players.online,
                maxPlayers: pingRes.players.max,
                playerList,
                uptime,
                serverIp: DISPLAY_IP,
                bedrockIp: BEDROCK_IP
            });
        });
    } catch (err) {
        res.json({ status: 'offline', players: 0, maxPlayers: 20, playerList: [], uptime: null, serverIp: DISPLAY_IP, bedrockIp: BEDROCK_IP });
    }
});

// ---------------------------------------------------------
// Container Stats API (Authenticated) — real docker metrics
// ---------------------------------------------------------
app.get('/api/stats', authenticateAny, async (req, res) => {
    const empty = { running: false, cpuPercent: 0, memUsed: 0, memLimit: 0, memPercent: 0, rxBytes: 0, txBytes: 0 };
    try {
        const container = docker.getContainer('minecraft');
        const info = await container.inspect();
        if (!info.State.Running) return res.json(empty);

        const s = await container.stats({ stream: false });

        // CPU % — standard docker delta formula
        let cpuPercent = 0;
        const cpuDelta = s.cpu_stats.cpu_usage.total_usage - s.precpu_stats.cpu_usage.total_usage;
        const sysDelta = s.cpu_stats.system_cpu_usage - (s.precpu_stats.system_cpu_usage || 0);
        const cores = s.cpu_stats.online_cpus || (s.cpu_stats.cpu_usage.percpu_usage || [1]).length;
        if (cpuDelta > 0 && sysDelta > 0) {
            cpuPercent = (cpuDelta / sysDelta) * cores * 100;
        }

        // Memory (subtract cache when available, like `docker stats`)
        const cache = (s.memory_stats.stats && (s.memory_stats.stats.cache || s.memory_stats.stats.inactive_file)) || 0;
        const memUsed = Math.max(0, (s.memory_stats.usage || 0) - cache);
        const memLimit = s.memory_stats.limit || 0;
        const memPercent = memLimit > 0 ? (memUsed / memLimit) * 100 : 0;

        // Network — sum across interfaces
        let rxBytes = 0, txBytes = 0;
        if (s.networks) {
            for (const net of Object.values(s.networks)) {
                rxBytes += net.rx_bytes || 0;
                txBytes += net.tx_bytes || 0;
            }
        }

        res.json({
            running: true,
            cpuPercent: Math.round(cpuPercent * 10) / 10,
            memUsed, memLimit,
            memPercent: Math.round(memPercent * 10) / 10,
            rxBytes, txBytes
        });
    } catch (err) {
        res.json(empty);
    }
});

// ---------------------------------------------------------
// Power API (Authenticated)
// ---------------------------------------------------------
app.post('/api/power', authenticateAny, async (req, res) => {
    const { action } = req.body;
    try {
        const container = docker.getContainer('minecraft');
        if (action === 'start') await container.start();
        else if (action === 'stop') await container.stop();
        else if (action === 'restart') await container.restart();
        else return res.status(400).json({ error: 'Invalid action' });
        res.json({ success: true, action });
    } catch (err) {
        // Docker throws if already started/stopped
        res.json({ success: true, action, note: err.message });
    }
});

// ---------------------------------------------------------
// Logs API (Admin Only)
// ---------------------------------------------------------
app.get('/api/logs', authenticateAdmin, async (req, res) => {
    try {
        const container = docker.getContainer('minecraft');
        const logs = await container.logs({ tail: 200, stdout: true, stderr: true });
        const cleanLogs = logs.toString('utf8').replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, '');
        res.send(cleanLogs);
    } catch (err) {
        res.status(500).send('Could not fetch logs: ' + err.message);
    }
});

// ---------------------------------------------------------
// File Manager (Admin Only)
// ---------------------------------------------------------
app.get('/api/files/list', authenticateAdmin, (req, res) => {
    let subPath = (req.query.path || '').replace(/\.\./g, '');
    const targetDir = path.join(DATA_DIR, subPath);
    if (!fs.existsSync(targetDir)) return res.json([]);
    try {
        const entries = fs.readdirSync(targetDir, { withFileTypes: true });
        const result = entries.map(f => ({
            name: f.name,
            isDir: f.isDirectory(),
            size: f.isDirectory() ? 0 : fs.statSync(path.join(targetDir, f.name)).size
        }));
        result.sort((a, b) => (b.isDir - a.isDir) || a.name.localeCompare(b.name));
        res.json(result);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/api/files/read', authenticateAdmin, (req, res) => {
    let subPath = (req.query.path || '').replace(/\.\./g, '');
    const target = path.join(DATA_DIR, subPath);
    if (!fs.existsSync(target)) return res.status(404).json({ error: 'Not found' });
    try {
        const content = fs.readFileSync(target, 'utf8');
        res.send(content);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/api/files/save', authenticateAdmin, (req, res) => {
    let subPath = (req.body.path || '').replace(/\.\./g, '');
    const target = path.join(DATA_DIR, subPath);
    try {
        fs.writeFileSync(target, req.body.content || '', 'utf8');
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

const upload = multer({ dest: '/tmp/' });
app.post('/api/files/upload', authenticateAdmin, upload.single('file'), (req, res) => {
    let subPath = (req.body.path || '').replace(/\.\./g, '');
    const targetDir = path.join(DATA_DIR, subPath);
    if (!fs.existsSync(targetDir)) return res.status(404).json({ error: 'Directory not found' });
    const dest = path.join(targetDir, req.file.originalname);
    try {
        fs.copyFileSync(req.file.path, dest);
        fs.unlinkSync(req.file.path);
        res.json({ success: true });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// ---------------------------------------------------------
// Minecraft Command Runner (Admin Only) — via rcon-cli
// ---------------------------------------------------------
app.post('/api/command', authenticateAdmin, (req, res) => {
    const { command } = req.body;
    if (!command || !command.trim()) return res.status(400).json({ error: 'No command provided' });
    // Strip leading slash if present (e.g. /seed -> seed)
    const cmd = command.trim().startsWith('/') ? command.trim().slice(1) : command.trim();
    execFile('docker', ['exec', 'minecraft', 'rcon-cli', cmd], { timeout: 10000 }, (err, stdout, stderr) => {
        if (err) return res.json({ success: false, output: err.message || 'Command failed' });
        res.json({ success: true, output: (stdout || stderr || 'Command sent').trim() });
    });
});

// ---------------------------------------------------------
// Backup Browser (Admin Only) — lists/deletes Google Drive backups
// ---------------------------------------------------------
app.get('/api/backups', authenticateAdmin, (req, res) => {
    execFile('rclone', ['lsjson', `gdrive:${GDRIVE_FOLDER}/`, '--config', RCLONE_CONFIG],
        { timeout: 30000 }, (err, stdout) => {
        if (err) {
            console.error('rclone lsjson error:', err.message);
            return res.json([]);
        }
        try {
            const files = JSON.parse(stdout || '[]');
            res.json(files.map(f => ({ name: f.Name, size: f.Size, modified: f.ModTime })));
        } catch (e) { res.json([]); }
    });
});

app.delete('/api/backups/:name', authenticateAdmin, (req, res) => {
    // Sanitize filename — only allow safe characters
    const name = req.params.name.replace(/[^a-zA-Z0-9._-]/g, '');
    if (!name) return res.status(400).json({ error: 'Invalid backup name' });
    execFile('rclone', ['deletefile', `gdrive:${GDRIVE_FOLDER}/${name}`, '--config', RCLONE_CONFIG],
        { timeout: 15000 }, (err) => {
        if (err) return res.json({ success: false, error: err.message });
        res.json({ success: true });
    });
});

// ---------------------------------------------------------
// Start
// ---------------------------------------------------------
app.listen(8080, '0.0.0.0', () => {
    console.log('Dashboard running on http://0.0.0.0:8080');
});
