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
const WebSocket = require('ws');
const os = require('os');
const nbt = require('prismarine-nbt');

const app = express();
const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// ─── Configuration ───────────────────────────────────────────────
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '';
const ADMIN_EMAIL = (process.env.ADMIN_EMAIL || 'yemularushikesh555@gmail.com').toLowerCase();
const JWT_SECRET = process.env.JWT_SECRET || 'supersecrethydrakey';
const DATA_DIR = process.env.DATA_DIR || '/data';
const USERDATA_DIR = process.env.USERDATA_DIR || '/app/userdata';
const SERVER_IP = process.env.SERVER_IP || 'minecraft';
const DISPLAY_IP = process.env.DISPLAY_IP || 'rushi-vps.me';
const BEDROCK_IP = process.env.BEDROCK_IP || null;
const RCLONE_CONFIG = process.env.RCLONE_CONFIG || '/root/.config/rclone/rclone.conf';
const GDRIVE_FOLDER = 'minecraft_backups';
const MINECRAFT_MEMORY_BYTES = Number(process.env.MINECRAFT_MEMORY_BYTES || 6 * 1024 * 1024 * 1024);
const MINECRAFT_CPU_CORES = Number(process.env.MINECRAFT_CPU_CORES || 2);
const MINECRAFT_MAX_PLAYERS = Number(process.env.MINECRAFT_MAX_PLAYERS || 10);

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(cookieParser());

// ─── React Frontend Serving ───────────────────────────────────────
app.use(express.static(path.join(__dirname, 'frontend/dist')));

app.get('/api/check_auth', (req, res) => {
    const token = req.cookies.session_token;
    if (!token) return res.json({ authenticated: false });
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        const user = findUserByEmail(decoded.email);
        if (!user) return res.json({ authenticated: false });
        res.json({ authenticated: true, user });
    } catch {
        res.json({ authenticated: false });
    }
});

// ─── User Database (JSON file) ──────────────────────────────────
const USERS_FILE = path.join(USERDATA_DIR, 'users.json');

function ensureUserDataDir() {
    if (!fs.existsSync(USERDATA_DIR)) fs.mkdirSync(USERDATA_DIR, { recursive: true });
    if (!fs.existsSync(USERS_FILE)) {
        saveUsers({ users: [{
            id: '1', email: ADMIN_EMAIL, name: 'Admin', picture: '',
            role: 'admin', allowedContainers: ['*'],
            createdAt: new Date().toISOString(), lastLogin: null
        }]});
    }
}
ensureUserDataDir();

function loadUsers() {
    try { return JSON.parse(fs.readFileSync(USERS_FILE, 'utf8')); }
    catch { return { users: [] }; }
}
function saveUsers(data) {
    fs.writeFileSync(USERS_FILE, JSON.stringify(data, null, 2));
}
function findUserByEmail(email) {
    return loadUsers().users.find(u => u.email.toLowerCase() === email.toLowerCase());
}

// ─── Google OAuth Token Verification ────────────────────────────
async function verifyGoogleToken(idToken) {
    const r = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    if (!r.ok) throw new Error('Invalid Google token');
    const p = await r.json();
    if (p.aud !== GOOGLE_CLIENT_ID) throw new Error('Token not issued for this application');
    if (p.email_verified !== 'true' && p.email_verified !== true) throw new Error('Email not verified');
    return { email: p.email, name: p.name || p.email.split('@')[0], picture: p.picture || '' };
}

// ─── Auth Middleware ────────────────────────────────────────────
function authenticateUser(req, res, next) {
    const token = req.cookies.session_token;
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        const user = findUserByEmail(decoded.email);
        if (!user) return res.status(401).json({ error: 'User removed' });
        req.user = user;
        next();
    } catch { res.status(401).json({ error: 'Session expired' }); }
}

function authenticateAdmin(req, res, next) {
    const token = req.cookies.session_token;
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        const user = findUserByEmail(decoded.email);
        if (!user || user.role !== 'admin') return res.status(403).json({ error: 'Admin access required' });
        req.user = user;
        next();
    } catch { res.status(401).json({ error: 'Session expired' }); }
}

// ─── Public Config (exposes Client ID to frontend) ──────────────
app.get('/api/config', (req, res) => {
    res.json({ googleClientId: GOOGLE_CLIENT_ID });
});

// ─── Auth Routes ────────────────────────────────────────────────
app.post('/api/auth/google', async (req, res) => {
    try {
        const { credential } = req.body;
        if (!credential) return res.status(400).json({ error: 'No credential' });

        const gUser = await verifyGoogleToken(credential);
        let user = findUserByEmail(gUser.email);

        if (!user) {
            // Auto-create admin
            if (gUser.email.toLowerCase() === ADMIN_EMAIL) {
                const db = loadUsers();
                user = {
                    id: Date.now().toString(), email: gUser.email.toLowerCase(),
                    name: gUser.name, picture: gUser.picture,
                    role: 'admin', allowedContainers: ['*'],
                    createdAt: new Date().toISOString(), lastLogin: new Date().toISOString()
                };
                db.users.push(user);
                saveUsers(db);
            } else {
                return res.status(403).json({ error: 'Access denied. Ask the admin to add your Google account.' });
            }
        } else {
            // Update profile from Google on each login
            const db = loadUsers();
            const idx = db.users.findIndex(u => u.email.toLowerCase() === gUser.email.toLowerCase());
            if (idx >= 0) {
                db.users[idx].name = gUser.name;
                db.users[idx].picture = gUser.picture;
                db.users[idx].lastLogin = new Date().toISOString();
                saveUsers(db);
                user = db.users[idx];
            }
        }

        const token = jwt.sign({ email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        res.cookie('session_token', token, { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 7*24*60*60*1000 });
        res.json({ success: true, user: { email: user.email, name: user.name, picture: user.picture, role: user.role, allowedContainers: user.allowedContainers } });
    } catch (err) {
        console.error('Auth error:', err.message);
        res.status(401).json({ error: err.message });
    }
});

app.get('/api/auth/me', (req, res) => {
    const token = req.cookies.session_token;
    if (!token) return res.json({ user: null });
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        const user = findUserByEmail(decoded.email);
        if (!user) return res.json({ user: null });
        res.json({ user: { id: user.id, email: user.email, name: user.name, picture: user.picture, role: user.role, allowedContainers: user.allowedContainers } });
    } catch { res.json({ user: null }); }
});

app.post('/api/logout', (req, res) => {
    res.clearCookie('session_token');
    res.clearCookie('admin_token');
    res.clearCookie('friend_token');
    res.json({ success: true });
});

// GET /logout - clears session and redirects to home (handles button clicks)
app.get('/logout', (req, res) => {
    res.clearCookie('session_token');
    res.clearCookie('admin_token');
    res.clearCookie('friend_token');
    res.redirect('/');
});

// ─── System Stats (Admin) ───────────────────────────────────────
app.get('/api/system/stats', authenticateAdmin, async (req, res) => {
    try {
        const cpus = os.cpus();
        let totalIdle = 0, totalTick = 0;
        cpus.forEach(c => { for (const t in c.times) totalTick += c.times[t]; totalIdle += c.times.idle; });
        const cpuPercent = Math.round((1 - totalIdle / totalTick) * 1000) / 10;

        const totalMem = os.totalmem();
        const usedMem = totalMem - os.freemem();

        const diskP = new Promise(resolve => {
            execFile('df', ['--output=size,used,avail,pcent', '-B1', '/'], (err, stdout) => {
                if (err) return resolve({ total: 0, used: 0, free: 0, percent: 0 });
                const parts = stdout.trim().split('\n').slice(1)[0]?.trim().split(/\s+/) || [];
                resolve({ total: +parts[0]||0, used: +parts[1]||0, free: +parts[2]||0, percent: parseInt(parts[3])||0 });
            });
        });
        const gdriveP = new Promise(resolve => {
            execFile('rclone', ['about', 'gdrive:', '--json', '--config', RCLONE_CONFIG], { timeout: 15000 }, (err, stdout) => {
                if (err) return resolve({ total: 0, used: 0, free: 0, trashed: 0 });
                try { const d = JSON.parse(stdout); resolve({ total: d.total||0, used: d.used||0, free: d.free||0, trashed: d.trashed||0 }); }
                catch { resolve({ total: 0, used: 0, free: 0, trashed: 0 }); }
            });
        });

        const [disk, gdrive] = await Promise.all([diskP, gdriveP]);
        res.json({
            cpu: { count: cpus.length, percent: cpuPercent, model: cpus[0]?.model || '' },
            memory: { total: totalMem, used: usedMem, free: totalMem - usedMem, percent: Math.round(usedMem/totalMem*1000)/10 },
            disk, gdrive
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ─── Deep Analytics & System Controls ─────────────────────────────
app.post('/api/system/clearcache', authenticateAdmin, async (req, res) => {
    try {
        await docker.run('alpine', ['sh', '-c', 'sync; echo 3 > /proc/sys/vm/drop_caches'], process.stdout, {
            HostConfig: { Privileged: true, Binds: ['/proc:/proc'] }
        });
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/system/disk-breakdown', authenticateAdmin, async (req, res) => {
    try {
        execFile('du', ['-sh', '/data', '/app', '/var/lib/docker/containers'], (err, stdout) => {
            const lines = (stdout || '').trim().split('\n').filter(Boolean);
            const breakdown = lines.map(line => {
                const parts = line.split(/\s+/);
                return { path: parts[1], size: parts[0] };
            });
            res.json(breakdown);
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// ─── Minecraft Specific Configs ─────────────────────────────────
app.get('/api/minecraft/properties', authenticateUser, (req, res) => {
    try {
        const content = fs.readFileSync(path.join(DATA_DIR, 'server.properties'), 'utf8');
        res.json({ content });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/minecraft/properties', authenticateUser, (req, res) => {
    try {
        fs.writeFileSync(path.join(DATA_DIR, 'server.properties'), req.body.content);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/minecraft/players/:type', authenticateUser, (req, res) => {
    const type = req.params.type;
    const valid = ['whitelist', 'ops', 'banned-players'];
    if (!valid.includes(type)) return res.status(400).json({ error: 'Invalid type' });
    try {
        const file = path.join(DATA_DIR, `${type}.json`);
        if (!fs.existsSync(file)) return res.json([]);
        const content = JSON.parse(fs.readFileSync(file, 'utf8'));
        res.json(content);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/minecraft/players/:type', authenticateUser, (req, res) => {
    const type = req.params.type;
    const valid = ['whitelist', 'ops', 'banned-players'];
    if (!valid.includes(type)) return res.status(400).json({ error: 'Invalid type' });
    try {
        const file = path.join(DATA_DIR, `${type}.json`);
        fs.writeFileSync(file, JSON.stringify(req.body, null, 2));
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/minecraft/player/:name/stats', authenticateUser, async (req, res) => {
    const name = req.params.name;
    try {
        // Find UUID from usercache.json
        const cacheFile = path.join(DATA_DIR, 'usercache.json');
        if (!fs.existsSync(cacheFile)) return res.status(404).json({ error: 'Player not found in cache' });
        
        const cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
        const playerEntry = cache.find(p => p.name.toLowerCase() === name.toLowerCase());
        if (!playerEntry) return res.status(404).json({ error: 'Player not found' });
        
        const uuid = playerEntry.uuid;
        const datFile = path.join(DATA_DIR, 'world', 'playerdata', `${uuid}.dat`);
        if (!fs.existsSync(datFile)) return res.status(404).json({ error: 'Player data not found' });
        
        const { parsed } = await nbt.parse(fs.readFileSync(datFile));
        const val = parsed.value;
        
        // Extract basic stats
        const pos = val.Pos ? val.Pos.value.value : [0,0,0];
        const dim = val.Dimension ? val.Dimension.value : 'minecraft:overworld';
        const health = val.Health ? val.Health.value : 0;
        const food = val.foodLevel ? val.foodLevel.value : 0;
        const xp = val.XpLevel ? val.XpLevel.value : 0;
        
        // Extract inventory (including armor/offhand)
        const invRaw = val.Inventory ? val.Inventory.value.value : [];
        const inventory = invRaw.map(item => ({
            slot: item.Slot.value,
            id: item.id.value,
            count: item.Count.value
        }));
        
        res.json({
            uuid, name,
            dimension: dim,
            position: { x: pos[0], y: pos[1], z: pos[2] },
            health, food, xp,
            inventory
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ─── Container Management ───────────────────────────────────────
app.get('/api/containers', authenticateUser, async (req, res) => {
    try {
        const containers = await docker.listContainers({ all: true });
        const results = [];

        for (const c of containers) {
            const name = c.Names[0]?.replace(/^\//, '') || 'unknown';
            // Filter by user access
            if (req.user.role !== 'admin') {
                const allowed = req.user.allowedContainers || [];
                if (!allowed.includes('*') && !allowed.includes(name)) continue;
            }

            const info = { name, image: c.Image, state: c.State, status: c.Status, ports: c.Ports, cpu: 0, memUsed: 0, memLimit: 0, memPercent: 0 };

            if (c.State === 'running') {
                try {
                    const ct = docker.getContainer(c.Id);
                    const s = await ct.stats({ stream: false });
                    const cpuD = s.cpu_stats.cpu_usage.total_usage - s.precpu_stats.cpu_usage.total_usage;
                    const sysD = s.cpu_stats.system_cpu_usage - (s.precpu_stats.system_cpu_usage || 0);
                    const cores = s.cpu_stats.online_cpus || 1;
                    if (cpuD > 0 && sysD > 0) info.cpu = Math.round(cpuD / sysD * cores * 1000) / 10;
                    const cache = (s.memory_stats.stats && (s.memory_stats.stats.cache || s.memory_stats.stats.inactive_file)) || 0;
                    info.memUsed = Math.max(0, (s.memory_stats.usage || 0) - cache);
                    info.memLimit = s.memory_stats.limit || 0;
                    info.memPercent = info.memLimit > 0 ? Math.round(info.memUsed / info.memLimit * 1000) / 10 : 0;
                } catch {}
            }
            results.push(info);
        }
        res.json(results);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/containers/:name/power', authenticateUser, async (req, res) => {
    const { name } = req.params;
    const { action } = req.body;
    if (req.user.role !== 'admin') {
        const allowed = req.user.allowedContainers || [];
        if (!allowed.includes('*') && !allowed.includes(name)) return res.status(403).json({ error: 'No access' });
    }
    try {
        const container = docker.getContainer(name);
        if (action === 'start') await container.start();
        else if (action === 'stop') await container.stop();
        else if (action === 'restart') await container.restart();
        else return res.status(400).json({ error: 'Invalid action' });
        res.json({ success: true, action });
    } catch (err) { res.json({ success: true, action, note: err.message }); }
});

// ─── User Management (Admin) ────────────────────────────────────
app.get('/api/users', authenticateAdmin, (req, res) => {
    res.json(loadUsers().users.map(u => ({
        id: u.id, email: u.email, name: u.name, picture: u.picture,
        role: u.role, allowedContainers: u.allowedContainers,
        lastLogin: u.lastLogin, createdAt: u.createdAt
    })));
});

app.post('/api/users', authenticateAdmin, (req, res) => {
    const { email, role, allowedContainers } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });
    const db = loadUsers();
    if (db.users.find(u => u.email.toLowerCase() === email.toLowerCase()))
        return res.status(409).json({ error: 'User already exists' });
    const user = {
        id: Date.now().toString(), email: email.toLowerCase(),
        name: email.split('@')[0], picture: '',
        role: role || 'user', allowedContainers: allowedContainers || [],
        createdAt: new Date().toISOString(), lastLogin: null
    };
    db.users.push(user);
    saveUsers(db);
    res.json(user);
});

app.put('/api/users/:id', authenticateAdmin, (req, res) => {
    const { role, allowedContainers } = req.body;
    const db = loadUsers();
    const idx = db.users.findIndex(u => u.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Not found' });
    if (db.users[idx].email === req.user.email && role && role !== 'admin')
        return res.status(400).json({ error: 'Cannot demote yourself' });
    if (role !== undefined) db.users[idx].role = role;
    if (allowedContainers !== undefined) db.users[idx].allowedContainers = allowedContainers;
    saveUsers(db);
    res.json(db.users[idx]);
});

app.delete('/api/users/:id', authenticateAdmin, (req, res) => {
    const db = loadUsers();
    const idx = db.users.findIndex(u => u.id === req.params.id);
    if (idx < 0) return res.status(404).json({ error: 'Not found' });
    if (db.users[idx].email === req.user.email) return res.status(400).json({ error: 'Cannot delete yourself' });
    db.users.splice(idx, 1);
    saveUsers(db);
    res.json({ success: true });
});

// ═══════════════════════════════════════════════════════════════
// Minecraft-Specific Endpoints (preserved from original)
// ═══════════════════════════════════════════════════════════════

// The dashboard needs a fast first paint. Keep the relatively slow game-server
// ping out of the request path and return one cached container snapshot instead.
const minecraftPing = { checkedAt: 0, online: null, players: 0, maxPlayers: MINECRAFT_MAX_PLAYERS, playerList: [] };
let minecraftPingInFlight = false;
let minecraftOverview = null;
let minecraftOverviewExpiresAt = 0;
let minecraftOverviewInFlight = null;

function refreshMinecraftPing() {
    const now = Date.now();
    if (minecraftPingInFlight || now - minecraftPing.checkedAt < 3000) return;
    minecraftPingInFlight = true;
    const server = new mcping.MinecraftServer(SERVER_IP, 25565);
    server.ping(2500, 767, (err, pingRes) => {
        minecraftPing.checkedAt = Date.now();
        minecraftPing.online = !err;
        minecraftPing.players = err ? 0 : pingRes.players.online;
        minecraftPing.maxPlayers = err ? MINECRAFT_MAX_PLAYERS : pingRes.players.max;
        minecraftPing.playerList = err ? [] : (pingRes.players.sample || []).map(p => p.name);
        minecraftPingInFlight = false;
        // A fresh ping can be reflected immediately by the next dashboard poll.
        minecraftOverviewExpiresAt = 0;
    });
}

function cpuLimitFor(info) {
    const host = info.HostConfig || {};
    let detected = 0;
    if (host.NanoCpus > 0) detected = host.NanoCpus / 1e9;
    else if (host.CpuQuota > 0 && host.CpuPeriod > 0) detected = host.CpuQuota / host.CpuPeriod;
    else if (host.CpusetCpus) {
        detected = host.CpusetCpus.split(',').reduce((count, segment) => {
            const [start, end] = segment.split('-').map(Number);
            return count + (Number.isFinite(end) ? end - start + 1 : 1);
        }, 0);
    }
    return Math.max(0.1, Math.min(detected || MINECRAFT_CPU_CORES, MINECRAFT_CPU_CORES));
}

async function collectMinecraftOverview() {
    const fallback = {
        status: 'offline', players: 0, maxPlayers: MINECRAFT_MAX_PLAYERS, playerList: [], uptime: null,
        serverIp: DISPLAY_IP, bedrockIp: BEDROCK_IP, running: false, cpuPercent: 0, cpuCores: MINECRAFT_CPU_CORES,
        memUsed: 0, memLimit: MINECRAFT_MEMORY_BYTES, memPercent: 0, rxBytes: 0, txBytes: 0,
    };
    try {
        const container = docker.getContainer('minecraft');
        const info = await container.inspect();
        if (!info.State.Running) return fallback;

        // Trigger a game ping in the background; never make the UI wait for it.
        refreshMinecraftPing();
        const stats = await container.stats({ stream: false });
        const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - stats.precpu_stats.cpu_usage.total_usage;
        const systemDelta = stats.cpu_stats.system_cpu_usage - (stats.precpu_stats.system_cpu_usage || 0);
        const onlineCpus = stats.cpu_stats.online_cpus || (stats.cpu_stats.cpu_usage.percpu_usage || [1]).length;
        const cpuCores = cpuLimitFor(info);
        let hostRelativeCpu = 0;
        if (cpuDelta > 0 && systemDelta > 0) hostRelativeCpu = (cpuDelta / systemDelta) * onlineCpus * 100;
        // Present CPU as a percentage of Minecraft's two allocated cores, not of the VPS.
        const cpuPercent = Math.min(100, Math.max(0, hostRelativeCpu / cpuCores));
        const cache = (stats.memory_stats.stats && (stats.memory_stats.stats.cache || stats.memory_stats.stats.inactive_file)) || 0;
        const memUsed = Math.max(0, (stats.memory_stats.usage || 0) - cache);
        const dockerLimit = stats.memory_stats.limit || MINECRAFT_MEMORY_BYTES;
        const memLimit = Math.min(dockerLimit, MINECRAFT_MEMORY_BYTES);
        const memPercent = Math.min(100, Math.max(0, (memUsed / memLimit) * 100));
        let rxBytes = 0, txBytes = 0;
        if (stats.networks) for (const net of Object.values(stats.networks)) { rxBytes += net.rx_bytes || 0; txBytes += net.tx_bytes || 0; }
        const reachable = minecraftPing.online;
        return {
            status: reachable === false ? 'starting' : 'online',
            players: reachable ? minecraftPing.players : 0,
            maxPlayers: reachable ? minecraftPing.maxPlayers : MINECRAFT_MAX_PLAYERS,
            playerList: reachable ? minecraftPing.playerList : [],
            uptime: info.State.StartedAt, serverIp: DISPLAY_IP, bedrockIp: BEDROCK_IP, running: true,
            cpuPercent: Math.round(cpuPercent * 10) / 10, cpuCores,
            memUsed, memLimit, memPercent: Math.round(memPercent * 10) / 10, rxBytes, txBytes,
        };
    } catch { return fallback; }
}

async function getMinecraftOverview() {
    if (minecraftOverview && Date.now() < minecraftOverviewExpiresAt) return minecraftOverview;
    if (!minecraftOverviewInFlight) {
        minecraftOverviewInFlight = collectMinecraftOverview().then(data => {
            minecraftOverview = data;
            minecraftOverviewExpiresAt = Date.now() + 1500;
            return data;
        }).finally(() => { minecraftOverviewInFlight = null; });
    }
    return minecraftOverviewInFlight;
}

app.get('/api/minecraft/overview', authenticateUser, async (req, res) => {
    res.set('Cache-Control', 'no-store');
    res.json(await getMinecraftOverview());
});

// Keep these routes compatible for existing clients while using the shared fast snapshot.
app.get('/api/status', authenticateUser, async (req, res) => {
    const data = await getMinecraftOverview();
    res.json({ status: data.status, players: data.players, maxPlayers: data.maxPlayers, playerList: data.playerList, uptime: data.uptime, serverIp: data.serverIp, bedrockIp: data.bedrockIp });
});

app.get('/api/stats', authenticateUser, async (req, res) => {
    const data = await getMinecraftOverview();
    res.json({ running: data.running, cpuPercent: data.cpuPercent, cpuCores: data.cpuCores, memUsed: data.memUsed, memLimit: data.memLimit, memPercent: data.memPercent, rxBytes: data.rxBytes, txBytes: data.txBytes });
});

app.post('/api/power', authenticateUser, async (req, res) => {
    const { action } = req.body;
    try {
        const container = docker.getContainer('minecraft');
        if (action === 'start') await container.start();
        else if (action === 'stop') await container.stop();
        else if (action === 'restart') await container.restart();
        else return res.status(400).json({ error: 'Invalid action' });
        res.json({ success: true, action });
    } catch (err) { res.json({ success: true, action, note: err.message }); }
});

app.get('/api/logs', authenticateUser, async (req, res) => {
    try {
        const container = docker.getContainer('minecraft');
        const logs = await container.logs({ tail: 200, stdout: true, stderr: true });
        res.send(logs.toString('utf8').replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, ''));
    } catch (err) { res.status(500).send('Could not fetch logs: ' + err.message); }
});

// File Manager (Admin Only)
app.get('/api/files/list', authenticateAdmin, (req, res) => {
    let subPath = (req.query.path || '').replace(/\.\./g, '');
    const targetDir = path.join(DATA_DIR, subPath);
    if (!fs.existsSync(targetDir)) return res.json([]);
    try {
        const entries = fs.readdirSync(targetDir, { withFileTypes: true });
        const result = entries.map(f => ({ name: f.name, isDir: f.isDirectory(), size: f.isDirectory() ? 0 : fs.statSync(path.join(targetDir, f.name)).size }));
        result.sort((a, b) => (b.isDir - a.isDir) || a.name.localeCompare(b.name));
        res.json(result);
    } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/files/read', authenticateAdmin, (req, res) => {
    let subPath = (req.query.path || '').replace(/\.\./g, '');
    const target = path.join(DATA_DIR, subPath);
    if (!fs.existsSync(target)) return res.status(404).json({ error: 'Not found' });
    try { res.send(fs.readFileSync(target, 'utf8')); }
    catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/files/save', authenticateAdmin, (req, res) => {
    let subPath = (req.body.path || '').replace(/\.\./g, '');
    const target = path.join(DATA_DIR, subPath);
    try { fs.writeFileSync(target, req.body.content || '', 'utf8'); res.json({ success: true }); }
    catch (e) { res.status(500).json({ error: e.message }); }
});

const upload = multer({ dest: '/tmp/' });
app.post('/api/files/upload', authenticateAdmin, upload.single('file'), (req, res) => {
    let subPath = (req.body.path || '').replace(/\.\./g, '');
    const targetDir = path.join(DATA_DIR, subPath);
    if (!fs.existsSync(targetDir)) return res.status(404).json({ error: 'Directory not found' });
    const dest = path.join(targetDir, req.file.originalname);
    try { fs.copyFileSync(req.file.path, dest); fs.unlinkSync(req.file.path); res.json({ success: true }); }
    catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/command', authenticateAdmin, (req, res) => {
    const { command } = req.body;
    if (!command || !command.trim()) return res.status(400).json({ error: 'No command' });
    const cmd = command.trim().startsWith('/') ? command.trim().slice(1) : command.trim();
    execFile('docker', ['exec', 'minecraft', 'rcon-cli', cmd], { timeout: 10000 }, (err, stdout, stderr) => {
        if (err) return res.json({ success: false, output: err.message || 'Command failed' });
        res.json({ success: true, output: (stdout || stderr || 'Command sent').trim() });
    });
});

app.get('/api/backups', authenticateAdmin, (req, res) => {
    execFile('rclone', ['lsjson', `gdrive:${GDRIVE_FOLDER}/`, '--config', RCLONE_CONFIG], { timeout: 30000 }, (err, stdout) => {
        if (err) return res.json([]);
        try { res.json(JSON.parse(stdout || '[]').map(f => ({ name: f.Name, size: f.Size, modified: f.ModTime }))); }
        catch { res.json([]); }
    });
});

app.delete('/api/backups/:name', authenticateAdmin, (req, res) => {
    const name = req.params.name.replace(/[^a-zA-Z0-9._-]/g, '');
    if (!name) return res.status(400).json({ error: 'Invalid name' });
    execFile('rclone', ['deletefile', `gdrive:${GDRIVE_FOLDER}/${name}`, '--config', RCLONE_CONFIG], { timeout: 15000 }, (err) => {
        if (err) return res.json({ success: false, error: err.message });
        res.json({ success: true });
    });
});


// ─── SPA Catch-all (must be last route) ────────────────────────
app.use((req, res) => {
    if (req.path.startsWith('/api/') || req.path.startsWith('/auth/')) {
        return res.status(404).json({ error: 'Not found' });
    }
    res.sendFile(path.join(__dirname, 'frontend/dist/index.html'));
});

// ─── Start Server + WebSocket ───────────────────────────────────
const server = app.listen(8080, '0.0.0.0', () => console.log('Dashboard running on http://0.0.0.0:8080'));

const wss = new WebSocket.Server({ noServer: true });

server.on('upgrade', (request, socket, head) => {
    const cookies = request.headers.cookie;
    let token = null;
    if (cookies) { const m = cookies.match(/(?:^|;\s*)session_token=([^;]*)/); if (m) token = m[1]; }
    if (token) {
        try {
            jwt.verify(token, JWT_SECRET);
            if (request.url === '/api/logs/stream') {
                wss.handleUpgrade(request, socket, head, ws => wss.emit('connection', ws, request));
                return;
            }
        } catch {}
    }
    socket.destroy();
});

wss.on('connection', async (ws) => {
    let logStream = null;
    try {
        const container = docker.getContainer('minecraft');
        logStream = await container.logs({ follow: true, stdout: true, stderr: true, tail: 200 });
        container.modem.demuxStream(logStream, {
            write: chunk => { const t = chunk.toString('utf8').replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, ''); if (ws.readyState === WebSocket.OPEN) ws.send(t); }
        }, {
            write: chunk => { const t = chunk.toString('utf8').replace(/[\x00-\x09\x0B-\x1F\x7F-\x9F]/g, ''); if (ws.readyState === WebSocket.OPEN) ws.send(t); }
        });
    } catch (err) { if (ws.readyState === WebSocket.OPEN) { ws.send('Could not stream logs: ' + err.message); ws.close(); } }
    ws.on('close', () => { if (logStream && logStream.destroy) logStream.destroy(); });
});
