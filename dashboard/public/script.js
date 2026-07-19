// =============================================
//  State
// =============================================
let currentRole = null;    // 'admin' | 'friend' | null
let currentPath = '';      // File manager path
let editingFile = '';      // Currently editing file
let statusInterval = null;
let statsInterval = null;
let consoleInterval = null;
let clockInterval = null;
let rawLogs = '';          // Cached raw console text for client-side filtering
let prevPlayers = null;    // For delta arrow
let prevNet = null;        // { rx, tx, t } for per-second rate

const HISTORY = 60;
const cpuHist = [];
const memHist = [];

// =============================================
//  Page Navigation
// =============================================
function showPage(name) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById(`page-${name}`).classList.add('active');

    if (name === 'dashboard') {
        fetchStatus();
        fetchStats();
        if (!statusInterval) statusInterval = setInterval(fetchStatus, 8000);
        if (!statsInterval) statsInterval = setInterval(fetchStats, 5000);
        startClock();

        // Show admin rail if admin role
        const rail = document.getElementById('admin-rail');
        if (rail) rail.style.display = currentRole === 'admin' ? 'flex' : 'none';

        // Update role chip
        const chip = document.getElementById('role-chip');
        if (chip && currentRole) {
            chip.className = `role-chip ${currentRole}`;
            chip.textContent = currentRole === 'admin' ? 'Admin' : 'Friend';
        }

        // Auto-open console drawer for admins
        if (currentRole === 'admin') {
            openDrawer();
            refreshLogs();
        }
    } else {
        if (statusInterval) { clearInterval(statusInterval); statusInterval = null; }
        if (statsInterval) { clearInterval(statsInterval); statsInterval = null; }
        if (clockInterval) { clearInterval(clockInterval); clockInterval = null; }
        stopConsoleAuto();
    }
}

function startClock() {
    const el = document.getElementById('cmd-clock');
    if (!el) return;
    const tick = () => el.textContent = new Date().toLocaleTimeString([], { hour12: false });
    tick();
    if (!clockInterval) clockInterval = setInterval(tick, 1000);
}

// =============================================
//  Login
// =============================================
function switchLoginTab(tab) {
    document.querySelectorAll('.login-tab').forEach(t => {
        const on = t.dataset.tab === tab;
        t.classList.toggle('active', on);
        t.setAttribute('aria-selected', on ? 'true' : 'false');
    });
    document.querySelectorAll('.login-form').forEach(f => f.classList.remove('active'));
    document.getElementById(`login-${tab}`).classList.add('active');
    document.getElementById('login-error').textContent = '';
    const glider = document.getElementById('tab-glider');
    if (glider) glider.classList.toggle('right', tab === 'admin');
    const focusId = tab === 'friend' ? 'input-pin' : 'input-admin-pass';
    setTimeout(() => document.getElementById(focusId)?.focus(), 50);
}

function loginError(msg) {
    const el = document.getElementById('login-error');
    el.textContent = msg;
    el.classList.remove('shake');
    void el.offsetWidth;
    el.classList.add('shake');
}

async function loginFriend() {
    const pin = document.getElementById('input-pin').value;
    if (!pin) return loginError('Please enter a PIN');
    try {
        const res = await fetch('/api/login/friend', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ pin })
        });
        const data = await res.json();
        if (data.success) { currentRole = 'friend'; showPage('dashboard'); }
        else loginError(data.error || 'Invalid PIN');
    } catch (e) { loginError('Connection error'); }
}

async function loginAdmin() {
    const password = document.getElementById('input-admin-pass').value;
    if (!password) return loginError('Please enter a password');
    try {
        const res = await fetch('/api/login/admin', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ password })
        });
        const data = await res.json();
        if (data.success) { currentRole = 'admin'; showPage('dashboard'); }
        else loginError(data.error || 'Wrong password');
    } catch (e) { loginError('Connection error'); }
}

async function logout() {
    await fetch('/api/logout', { method: 'POST' });
    currentRole = null;
    cpuHist.length = 0; memHist.length = 0;
    prevPlayers = null; prevNet = null;
    // Hide admin rail and close drawer
    const rail = document.getElementById('admin-rail');
    if (rail) rail.style.display = 'none';
    closeDrawer();
    stopConsoleAuto();
    showPage('login');
}

async function checkAuth() {
    try {
        const res = await fetch('/api/auth');
        const data = await res.json();
        if (data.role) { currentRole = data.role; showPage('dashboard'); }
    } catch (e) { /* stay on login */ }
}

// =============================================
//  Admin Rail / Drawer
// =============================================
function openDrawer() {
    document.getElementById('admin-drawer').classList.add('open');
}
function closeDrawer() {
    document.getElementById('admin-drawer').classList.remove('open');
}

function switchRailTab(btn, tab) {
    // Update rail button active states
    document.querySelectorAll('.rail-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');

    // Switch content tabs
    document.querySelectorAll('.rail-tab').forEach(t => t.classList.remove('active'));
    document.getElementById(`rail-${tab}`).classList.add('active');

    // Ensure drawer is open
    openDrawer();

    // Load appropriate content
    if (tab === 'console') refreshLogs();
    else stopConsoleAuto();
    if (tab === 'files') loadFiles();
    if (tab === 'plugins') loadPlugins();
    if (tab === 'backups') loadBackups();
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        const loginPage = document.getElementById('page-login');
        if (loginPage.classList.contains('active')) {
            const friendTab = document.getElementById('login-friend');
            if (friendTab.classList.contains('active')) loginFriend();
            else loginAdmin();
        }
    }
    if (e.key === 'Escape') closeEditor();
});

// =============================================
//  Number animation
// =============================================
function animateCount(el, target) {
    const start = parseInt(el.dataset.num || '0', 10);
    if (start === target) { el.textContent = target; return; }
    const dur = 500, t0 = performance.now();
    function step(now) {
        const p = Math.min((now - t0) / dur, 1);
        const eased = 1 - Math.pow(1 - p, 3);
        el.textContent = Math.round(start + (target - start) * eased);
        if (p < 1) requestAnimationFrame(step);
        else el.dataset.num = target;
    }
    requestAnimationFrame(step);
}

// =============================================
//  Status (players / online state / ping)
// =============================================
async function fetchStatus() {
    try {
        const t0 = performance.now();
        const res = await fetch('/api/status');
        if (res.status === 401) { showPage('login'); return; }
        const data = await res.json();
        const latency = Math.round(performance.now() - t0);

        // status tile
        const tile = document.getElementById('tile-status');
        tile.className = `metric-tile ${data.status}`;
        document.getElementById('status-text').textContent = data.status;
        const led = document.getElementById('status-led');
        led.className = 'led lg ' + (data.status === 'online' ? 'live' : data.status === 'starting' ? 'warn' : 'down');
        const footMap = { online: 'node running', starting: 'node booting', offline: 'node stopped' };
        document.getElementById('status-foot').textContent = footMap[data.status] || 'checking node';

        const nodeLed = document.getElementById('node-led');
        if (nodeLed) nodeLed.className = 'led ' + (data.status === 'online' ? 'live' : data.status === 'starting' ? 'warn' : 'down');

        // IP addresses
        if (data.serverIp) {
            const connJava = document.getElementById('conn-java');
            if (connJava) {
                connJava.textContent = data.serverIp;
                const btnJava = connJava.nextElementSibling;
                if (btnJava) btnJava.setAttribute('onclick', `copyText('${data.serverIp}', this)`);
            }
        }
        
        if (data.bedrockIp) {
            const connBedrock = document.getElementById('conn-bedrock');
            if (connBedrock) {
                connBedrock.textContent = data.bedrockIp;
                const btnBedrock = connBedrock.nextElementSibling;
                if (btnBedrock) btnBedrock.setAttribute('onclick', `copyText('${data.bedrockIp}', this)`);
            }
        }

        // players
        const playersEl = document.getElementById('stat-players');
        animateCount(playersEl, data.players);
        document.getElementById('stat-max').textContent = data.maxPlayers;
        document.getElementById('players-badge').textContent = data.players;

        // players delta
        const deltaEl = document.getElementById('players-delta');
        if (prevPlayers !== null && data.players !== prevPlayers) {
            const diff = data.players - prevPlayers;
            deltaEl.textContent = (diff > 0 ? '▲' : '▼') + Math.abs(diff);
            deltaEl.className = 'metric-delta ' + (diff > 0 ? 'up' : 'down');
        }
        prevPlayers = data.players;

        // capacity bar
        const fill = document.getElementById('capacity-fill');
        const ratio = data.maxPlayers > 0 ? Math.min(data.players / data.maxPlayers, 1) : 0;
        fill.style.width = (ratio * 100) + '%';
        fill.style.background = ratio >= 0.9 ? 'var(--red)' : ratio >= 0.6 ? 'var(--amber)' : 'var(--green)';

        // ping
        document.getElementById('stat-latency').textContent = data.status === 'online' ? latency : '--';

        // uptime
        const upEl = document.getElementById('stat-uptime');
        if (data.uptime) {
            const diff = Date.now() - new Date(data.uptime).getTime();
            const days = Math.floor(diff / 86400000);
            const hrs = Math.floor((diff % 86400000) / 3600000);
            const mins = Math.floor((diff % 3600000) / 60000);
            upEl.textContent = days > 0 ? `${days}d${hrs}h` : hrs > 0 ? `${hrs}h${mins}m` : `${mins}m`;
        } else upEl.textContent = '--';

        // players list
        const container = document.getElementById('players-container');
        if (data.playerList && data.playerList.length > 0) {
            container.innerHTML = data.playerList.map((name, i) => {
                const safe = escapeHtml(name);
                const head = `https://mc-heads.net/avatar/${encodeURIComponent(name)}/30`;
                return `<div class="player-item" style="animation-delay:${i * 45}ms">
                    <img class="player-avatar" src="${head}" alt="" loading="lazy" onerror="this.style.visibility='hidden'">
                    <span class="player-name">${safe}</span>
                    <span class="player-online-dot"></span>
                </div>`;
            }).join('');
        } else {
            container.innerHTML = `<div class="empty-state">${data.status === 'online' ? 'No players online' : 'Server offline'}</div>`;
        }

        const lu = document.getElementById('last-updated');
        if (lu) lu.textContent = 'synced ' + new Date().toLocaleTimeString([], { hour12: false });
    } catch (e) { console.error('Status fetch failed', e); }
}

// =============================================
//  Stats (real docker CPU / mem / net)
// =============================================
async function fetchStats() {
    try {
        const res = await fetch('/api/stats');
        if (res.status === 401) return;
        const s = await res.json();

        if (!s.running) {
            document.getElementById('stat-cpu').textContent = '--';
            document.getElementById('stat-mem').textContent = '--';
            document.getElementById('stat-rx').textContent = '--';
            document.getElementById('stat-tx').textContent = '--';
            document.getElementById('chart-cpu-now').textContent = '--%';
            document.getElementById('chart-mem-now').textContent = '--%';
            prevNet = null;
            return;
        }

        // CPU
        const cpu = s.cpuPercent || 0;
        document.getElementById('stat-cpu').textContent = cpu.toFixed(cpu >= 10 ? 0 : 1);
        document.getElementById('chart-cpu-now').textContent = cpu.toFixed(1) + '%';
        pushHist(cpuHist, cpu);

        // Memory (% of limit)
        const memPct = s.memPercent || 0;
        document.getElementById('stat-mem').textContent = memPct.toFixed(0);
        document.getElementById('stat-mem-unit').textContent = '%';
        document.getElementById('chart-mem-now').textContent = formatBytes(s.memUsed) + ' / ' + formatBytes(s.memLimit);
        pushHist(memHist, memPct);

        // Network rate (bytes/sec)
        const now = performance.now();
        if (prevNet) {
            const dt = (now - prevNet.t) / 1000;
            if (dt > 0) {
                const rxRate = Math.max(0, (s.rxBytes - prevNet.rx) / dt);
                const txRate = Math.max(0, (s.txBytes - prevNet.tx) / dt);
                document.getElementById('stat-rx').textContent = formatRate(rxRate);
                document.getElementById('stat-tx').textContent = formatRate(txRate);
            }
        }
        prevNet = { rx: s.rxBytes, tx: s.txBytes, t: now };

        // draw
        drawSpark('spark-cpu', cpuHist, 100);
        drawSpark('spark-mem', memHist, 100);
        drawArea('chart-cpu', cpuHist, 'cpu', 100);
        drawArea('chart-mem', memHist, 'mem', 100);
    } catch (e) { console.error('Stats fetch failed', e); }
}

function pushHist(arr, v) { arr.push(v); if (arr.length > HISTORY) arr.shift(); }

// =============================================
//  Chart renderers (dependency-free inline SVG)
// =============================================
function buildPath(data, w, h, max) {
    if (!data.length) return { line: '', area: '' };
    const n = data.length;
    const stepX = n > 1 ? w / (n - 1) : w;
    const pts = data.map((v, i) => {
        const x = i * stepX;
        const y = h - (Math.min(v, max) / max) * h;
        return [x, y];
    });
    const line = pts.map((p, i) => (i === 0 ? 'M' : 'L') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join(' ');
    const area = line + ` L${w.toFixed(1)} ${h} L0 ${h} Z`;
    return { line, area };
}

function drawSpark(id, data, max) {
    const svg = document.getElementById(id);
    if (!svg) return;
    const { line, area } = buildPath(data, 100, 28, max);
    svg.innerHTML = `<path class="fill" d="${area}"/><path d="${line}"/>`;
}

function drawArea(id, data, cls, max) {
    const svg = document.getElementById(id);
    if (!svg) return;
    const W = 300, H = 80;
    const { line, area } = buildPath(data, W, H, max);
    let grid = '';
    for (let i = 1; i < 4; i++) {
        const y = (H / 4) * i;
        grid += `<line class="grid-line" x1="0" y1="${y}" x2="${W}" y2="${y}"/>`;
    }
    svg.innerHTML = grid + `<path class="area ${cls}" d="${area}"/><path class="line ${cls}" d="${line}"/>`;
}

// =============================================
//  Power Controls
// =============================================
async function powerAction(action) {
    const btn = document.getElementById(`btn-${action}`);
    const label = btn.querySelector('span');
    const original = label.textContent;
    btn.disabled = true;
    btn.classList.add('loading');
    label.textContent = '…';

    try {
        const res = await fetch('/api/power', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action })
        });
        if (res.status === 401) { showPage('login'); return; }
        const data = await res.json();
        if (data.success) { showToast(`Server ${action} sent`, 'success'); setTimeout(() => { fetchStatus(); fetchStats(); }, 3000); }
        else showToast(data.error || 'Action failed', 'error');
    } catch (e) { showToast('Network error', 'error'); }

    setTimeout(() => {
        btn.disabled = false;
        btn.classList.remove('loading');
        label.textContent = original;
    }, 5000);
}

// =============================================
//  Admin Tabs (legacy — kept for compatibility)
// =============================================
function switchAdminTab(tab) {
    // Redirect to rail tab system
    const btn = document.getElementById(`rail-btn-${tab}`);
    if (btn) switchRailTab(btn, tab);
}

// =============================================
//  Console (Logs)
// =============================================
function classifyLine(line) {
    if (/\b(ERROR|SEVERE|Exception|FATAL)\b/i.test(line)) return 'lv-error';
    if (/\bWARN(ING)?\b/i.test(line)) return 'lv-warn';
    if (/\bINFO\b/i.test(line)) return 'lv-info';
    return 'lv-default';
}

function renderLogs() {
    const el = document.getElementById('console-output');
    const filter = (document.getElementById('console-search')?.value || '').toLowerCase();
    const lines = rawLogs.split('\n');
    const html = lines
        .filter(l => !filter || l.toLowerCase().includes(filter))
        .map(l => {
            let safe = escapeHtml(l);
            if (filter) {
                const re = new RegExp(`(${escapeRegex(filter)})`, 'gi');
                safe = safe.replace(re, '<mark>$1</mark>');
            }
            return `<span class="log-line ${classifyLine(l)}">${safe || '&nbsp;'}</span>`;
        }).join('');
    const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 40;
    el.innerHTML = html;
    if (atBottom) el.scrollTop = el.scrollHeight;
}

async function refreshLogs() {
    const btn = document.getElementById('btn-refresh-logs');
    btn?.classList.add('spinning');
    try {
        const res = await fetch('/api/logs');
        if (res.status === 401) return;
        rawLogs = await res.text();
        renderLogs();
    } catch (e) { console.error(e); }
    finally { setTimeout(() => btn?.classList.remove('spinning'), 500); }
}

function toggleConsoleAuto() {
    const on = document.getElementById('console-auto').checked;
    if (on) { refreshLogs(); consoleInterval = setInterval(refreshLogs, 3000); }
    else stopConsoleAuto();
}
function stopConsoleAuto() {
    if (consoleInterval) { clearInterval(consoleInterval); consoleInterval = null; }
    const cb = document.getElementById('console-auto');
    if (cb) cb.checked = false;
}

// =============================================
//  Minecraft Command Runner
// =============================================
async function sendCommand() {
    const input = document.getElementById('mc-cmd-input');
    const cmd = input.value.trim();
    if (!cmd) return;

    // Append command echo to console output
    const el = document.getElementById('console-output');
    el.innerHTML += `<span class="log-line lv-cmd">> /${cmd}</span>`;
    el.scrollTop = el.scrollHeight;
    input.value = '';

    try {
        const res = await fetch('/api/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ command: cmd })
        });
        const data = await res.json();
        const output = data.output || (data.success ? 'Done' : data.error || 'Failed');
        el.innerHTML += `<span class="log-line lv-cmd-out">${escapeHtml(output)}</span>`;
        el.scrollTop = el.scrollHeight;
    } catch (e) {
        el.innerHTML += `<span class="log-line lv-error">Network error sending command</span>`;
        el.scrollTop = el.scrollHeight;
    }
}

// =============================================
//  File Manager
// =============================================
function renderBreadcrumb() {
    const bc = document.getElementById('breadcrumb');
    const parts = currentPath ? currentPath.split('/') : [];
    let acc = '';
    let html = `<span class="crumb" onclick="loadFilesAbs('')">~</span>`;
    parts.forEach((p) => {
        acc = acc ? `${acc}/${p}` : p;
        html += `<span class="crumb-sep">/</span><span class="crumb" onclick="loadFilesAbs('${escapeAttr(acc)}')">${escapeHtml(p)}</span>`;
    });
    bc.innerHTML = html;
}

function loadFilesAbs(path) { currentPath = path; loadFiles(); }

async function loadFiles(subPath) {
    if (subPath === '..') currentPath = currentPath.split('/').slice(0, -1).join('/');
    else if (subPath !== undefined) currentPath = currentPath ? `${currentPath}/${subPath}` : subPath;

    renderBreadcrumb();
    const list = document.getElementById('files-list');
    list.innerHTML = Array.from({ length: 5 }).map(() => '<div class="skeleton skel-row"></div>').join('');

    try {
        const res = await fetch(`/api/files/list?path=${encodeURIComponent(currentPath)}`);
        if (res.status === 401) return;
        const files = await res.json();
        list.innerHTML = '';

        if (currentPath) {
            list.innerHTML = `<div class="file-row" onclick="loadFiles('..')">
                <span class="file-icon">↩</span><span class="file-name dir-name">..</span></div>`;
        }

        files.forEach((f, i) => {
            const icon = f.isDir ? '📁' : (f.name.endsWith('.jar') ? '🧩' : fileEmoji(f.name));
            const nameClass = f.isDir ? 'file-name dir-name' : 'file-name';
            const size = f.isDir ? '' : formatBytes(f.size);
            const nm = escapeAttr(f.name);
            const onclick = f.isDir ? `loadFiles('${nm}')` : `openEditor('${nm}')`;
            list.innerHTML += `<div class="file-row" style="animation-delay:${i * 18}ms" onclick="${onclick}">
                <span class="file-icon">${icon}</span>
                <span class="${nameClass}">${escapeHtml(f.name)}</span>
                <span class="file-size">${size}</span></div>`;
        });

        if (!files.length && !currentPath) list.innerHTML = '<div class="empty-state">Empty directory</div>';
    } catch (e) { console.error(e); }
}

function fileEmoji(name) {
    if (/\.(ya?ml|json|properties|conf|toml|txt|log)$/i.test(name)) return '📄';
    if (/\.(png|jpg|jpeg|gif)$/i.test(name)) return '🖼️';
    if (/\.(zip|gz|tar)$/i.test(name)) return '🗜️';
    return '📄';
}

async function openEditor(filename) {
    const filePath = currentPath ? `${currentPath}/${filename}` : filename;
    try {
        const res = await fetch(`/api/files/read?path=${encodeURIComponent(filePath)}`);
        if (res.status !== 200) { showToast('Cannot open this file', 'error'); return; }
        const content = await res.text();
        editingFile = filePath;
        document.getElementById('editor-title').textContent = filename;
        document.getElementById('editor-textarea').value = content;
        document.getElementById('editor-modal').classList.add('active');
    } catch (e) { console.error(e); }
}

function closeEditor() { document.getElementById('editor-modal').classList.remove('active'); }

async function saveFile() {
    const content = document.getElementById('editor-textarea').value;
    try {
        const res = await fetch('/api/files/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ path: editingFile, content })
        });
        const data = await res.json();
        if (data.success) { showToast('File saved', 'success'); closeEditor(); }
        else showToast(data.error, 'error');
    } catch (e) { showToast('Save failed', 'error'); }
}

// =============================================
//  Plugins
// =============================================
async function loadPlugins() {
    const list = document.getElementById('plugins-list');
    list.innerHTML = Array.from({ length: 3 }).map(() => '<div class="skeleton skel-row" style="height:54px"></div>').join('');
    try {
        const res = await fetch('/api/files/list?path=plugins');
        if (res.status === 401) return;
        const files = await res.json();
        const plugins = files.filter(f => !f.isDir);
        list.innerHTML = '';
        plugins.forEach((f, i) => {
            list.innerHTML += `<div class="plugin-item" style="animation-delay:${i * 35}ms">
                <div class="plugin-icon">🧩</div>
                <span class="plugin-name">${escapeHtml(f.name)}</span>
                <span class="plugin-size">${formatBytes(f.size)}</span></div>`;
        });
        if (!plugins.length) list.innerHTML = '<div class="empty-state" style="padding:2rem">No plugins found</div>';
    } catch (e) { console.error(e); }
}

// =============================================
//  Backup Browser
// =============================================
async function loadBackups() {
    const list = document.getElementById('backups-list');
    list.innerHTML = Array.from({ length: 3 }).map(() => '<div class="skeleton skel-row" style="height:60px"></div>').join('');
    try {
        const res = await fetch('/api/backups');
        if (res.status === 401) return;
        const backups = await res.json();
        list.innerHTML = '';
        if (!backups.length) {
            list.innerHTML = '<div class="empty-state" style="padding:2rem">No backups on Google Drive yet</div>';
            return;
        }
        backups.sort((a, b) => b.name.localeCompare(a.name)); // newest first
        backups.forEach((b, i) => {
            const date = b.modified ? new Date(b.modified).toLocaleString() : '—';
            list.innerHTML += `<div class="backup-item" style="animation-delay:${i * 40}ms">
                <span class="backup-icon">🗄️</span>
                <div class="backup-info">
                    <div class="backup-name">${escapeHtml(b.name)}</div>
                    <div class="backup-meta">${formatBytes(b.size)} &middot; ${date}</div>
                </div>
                <button class="backup-delete" onclick="deleteBackup('${escapeAttr(b.name)}')">Delete</button>
            </div>`;
        });
    } catch (e) {
        list.innerHTML = '<div class="empty-state" style="padding:2rem">Failed to load backups</div>';
        console.error(e);
    }
}

async function deleteBackup(name) {
    if (!confirm(`Delete backup "${name}" from Google Drive?`)) return;
    try {
        const res = await fetch(`/api/backups/${encodeURIComponent(name)}`, { method: 'DELETE' });
        const data = await res.json();
        if (data.success) { showToast('Backup deleted', 'success'); loadBackups(); }
        else showToast(data.error || 'Delete failed', 'error');
    } catch (e) { showToast('Network error', 'error'); }
}

async function handlePluginUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    const formData = new FormData();
    formData.append('file', file);
    formData.append('path', 'plugins');
    showToast(`Uploading ${file.name}…`, 'success');
    try {
        const res = await fetch('/api/files/upload', { method: 'POST', body: formData });
        const data = await res.json();
        if (data.success) { showToast('Plugin uploaded — restart to activate', 'success'); loadPlugins(); }
        else showToast(data.error, 'error');
    } catch (e) { showToast('Upload failed', 'error'); }
    event.target.value = '';
}

// =============================================
//  Utils
// =============================================
function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
function escapeAttr(str) { return String(str).replace(/'/g, "\\'").replace(/"/g, '&quot;'); }
function escapeRegex(str) { return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

function formatBytes(bytes) {
    if (!bytes || bytes < 1024) return (bytes || 0) + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + ' MB';
    return (bytes / 1073741824).toFixed(2) + ' GB';
}
function formatRate(bps) {
    if (bps < 1024) return Math.round(bps) + ' B/s';
    if (bps < 1048576) return (bps / 1024).toFixed(1) + ' KB/s';
    return (bps / 1048576).toFixed(1) + ' MB/s';
}

function copyText(text, btn) {
    navigator.clipboard.writeText(text);
    showToast('Copied to clipboard', 'success');
    if (btn) { btn.classList.add('copied'); setTimeout(() => btn.classList.remove('copied'), 1200); }
}

let toastTimer = null;
function showToast(msg, type = '') {
    const toast = document.getElementById('toast');
    toast.textContent = msg;
    toast.className = `toast ${type} show`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('show'), 3000);
}

// =============================================
//  Init
// =============================================
checkAuth();
