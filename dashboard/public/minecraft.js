let logSocket = null;
let currentFilePath = '';
let currentPlayerListType = 'whitelist';

// Chart instances
let cpuChart, ramChart;
const maxDataPoints = 30; // 30 ticks = 150 seconds of history at 5s intervals

document.addEventListener('DOMContentLoaded', async () => {
    const isAuth = await checkAuth();
    if (!isAuth) {
        window.location.href = '/';
        return;
    }

    updateUserChips();

    if (currentUser.role === 'admin' || (currentUser.allowedContainers && (currentUser.allowedContainers.includes('minecraft') || currentUser.allowedContainers.includes('*')))) {
        if (currentUser.role === 'admin') {
            document.getElementById('btn-back-hub').style.display = 'flex';
            document.getElementById('tab-files').style.display = 'flex';
            document.getElementById('tab-backups').style.display = 'flex';
            document.getElementById('quick-power').style.display = 'flex';
        }
        initCharts();
        startMinecraftDashboard();
    } else {
        window.location.href = '/hub';
    }
});

function toggleNav() {
    const sb = document.getElementById('mc-sidebar');
    sb.classList.toggle('collapsed');
}

function updateUserChips() {
    if (!currentUser) return;
    const nameEl = document.getElementById('mc-user-name');
    const avatarEl = document.getElementById('mc-user-avatar');
    if (nameEl) nameEl.textContent = currentUser.name || currentUser.email.split('@')[0];
    if (avatarEl && currentUser.picture) { avatarEl.src = currentUser.picture; avatarEl.style.display = 'block'; }
}

function startMinecraftDashboard() {
    fetchStatus();
    fetchStats();
    setInterval(fetchStatus, 5000);
    setInterval(fetchStats, 5000);
    connectLogStream();
    loadPropertiesGUI();
    loadPlayerList();
    if (currentUser.role === 'admin') {
        loadFiles();
        loadBackups();
    }
}

// ─── Charts ───────────────────────────────────────────────
function initCharts() {
    const commonOptions = {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 0 },
        scales: {
            x: { display: false },
            y: { beginAtZero: true, max: 100, grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#8b8da0', callback: v => v + '%' } }
        },
        plugins: { legend: { display: false }, tooltip: { enabled: false } },
        elements: { point: { radius: 0 }, line: { tension: 0.4, borderWidth: 2 } }
    };

    const ctxCpu = document.getElementById('cpuChart').getContext('2d');
    cpuChart = new Chart(ctxCpu, {
        type: 'line',
        data: { labels: Array(maxDataPoints).fill(''), datasets: [{ data: Array(maxDataPoints).fill(0), borderColor: '#6C5CE7', backgroundColor: 'rgba(108,92,231,0.1)', fill: true }] },
        options: commonOptions
    });

    const ctxRam = document.getElementById('ramChart').getContext('2d');
    ramChart = new Chart(ctxRam, {
        type: 'line',
        data: { labels: Array(maxDataPoints).fill(''), datasets: [{ data: Array(maxDataPoints).fill(0), borderColor: '#00D2FF', backgroundColor: 'rgba(0,210,255,0.1)', fill: true }] },
        options: commonOptions
    });
}

function updateChart(chart, value) {
    if (!chart) return;
    chart.data.datasets[0].data.push(value);
    chart.data.datasets[0].data.shift();
    chart.update();
}

// ─── Status ───────────────────────────────────────────────
async function fetchStatus() {
    try {
        const res = await fetch('/api/status');
        const d = await res.json();
        const badge = document.getElementById('status-badge');
        badge.textContent = d.status.charAt(0).toUpperCase() + d.status.slice(1);
        badge.className = 'status-badge ' + d.status;
        document.getElementById('node-led').className = 'led led-' + (d.status === 'online' ? 'green' : d.status === 'starting' ? 'yellow' : 'red');
        document.getElementById('player-count').textContent = d.players;
        
        if (d.version) document.getElementById('mc-version').textContent = d.version;

        const pct = d.maxPlayers > 0 ? d.players / d.maxPlayers : 0;
        const circ = 2 * Math.PI * 42;
        document.getElementById('player-ring').style.strokeDashoffset = circ * (1 - pct);

        if (d.uptime) {
            const mins = Math.floor((Date.now() - new Date(d.uptime).getTime()) / 60000);
            document.getElementById('status-uptime').textContent = mins < 60 ? `Up ${mins}m` : `Up ${Math.floor(mins/60)}h ${mins%60}m`;
        } else {
            document.getElementById('status-uptime').textContent = '';
        }

        if (d.serverIp) document.getElementById('conn-java').textContent = d.serverIp;
        if (d.bedrockIp) document.getElementById('conn-bedrock').textContent = d.bedrockIp;
    } catch {}
}

// ─── Stats ───────────────────────────────────────────────
async function fetchStats() {
    try {
        const res = await fetch('/api/stats');
        const s = await res.json();
        if (!s.running) {
            updateChart(cpuChart, 0);
            updateChart(ramChart, 0);
            return;
        }
        updateChart(cpuChart, Math.min(s.cpuPercent, 100));
        updateChart(ramChart, s.memPercent);
    } catch {}
}

// ─── Console Log Stream ───────────────────────────────────────────────
function connectLogStream() {
    if (logSocket) logSocket.close();
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    logSocket = new WebSocket(`${proto}//${location.host}/api/logs/stream`);
    const out = document.getElementById('console-output');
    logSocket.onmessage = (e) => {
        out.innerHTML += ansiToHtml(e.data);
        if (document.getElementById('autoscroll')?.checked) out.scrollTop = out.scrollHeight;
    };
    logSocket.onclose = () => { setTimeout(connectLogStream, 3000); };
    logSocket.onerror = () => logSocket.close();
}

function clearConsole() { document.getElementById('console-output').innerHTML = ''; }

async function sendCommand() {
    const input = document.getElementById('console-cmd');
    const cmd = input.value.trim();
    if (!cmd) return;
    input.value = '';
    try {
        const res = await fetch('/api/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ command: cmd })
        });
        const data = await res.json();
        const out = document.getElementById('console-output');
        out.innerHTML += `\n<span style="color:var(--accent);font-weight:700">&gt; ${cmd}</span>\n${ansiToHtml(data.output || '')}\n`;
        if (document.getElementById('autoscroll')?.checked) out.scrollTop = out.scrollHeight;
    } catch {}
}

function ansiToHtml(str) {
    str = str.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    const colors = {
        '0': '#000000', '1': '#AA0000', '2': '#00AA00', '3': '#AAAA00',
        '4': '#0000AA', '5': '#AA00AA', '6': '#00AAAA', '7': '#AAAAAA',
        '8': '#555555', '9': '#FF5555', '10': '#55FF55', '11': '#FFFF55',
        '12': '#5555FF', '13': '#FF55FF', '14': '#55FFFF', '15': '#FFFFFF'
    };
    let out = '', openSpan = false;
    const parts = str.split(/\x1B\[([0-9;]*)[mK]/);
    
    for (let i = 0; i < parts.length; i++) {
        if (i % 2 === 0) { out += parts[i]; continue; }
        const code = parts[i];
        if (code === '0' || code === '') {
            if (openSpan) { out += '</span>'; openSpan = false; }
        } else if (code.startsWith('38;5;')) {
            const colorId = code.split(';')[2];
            if (openSpan) out += '</span>';
            out += `<span style="color:${colors[colorId] || '#ccc'}">`;
            openSpan = true;
        } else {
            // Simple mapping for basic ANSI (30-37, 90-97)
            let color = '#ccc';
            if (code >= 30 && code <= 37) color = colors[code - 30];
            if (code >= 90 && code <= 97) color = colors[code - 90 + 8];
            if (openSpan) out += '</span>';
            out += `<span style="color:${color}">`;
            openSpan = true;
        }
    }
    if (openSpan) out += '</span>';
    return out;
}

// ─── Tabs ───────────────────────────────────────────────
function switchTab(name) {
    document.querySelectorAll('.nav-item').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.toggle('active', p.id === 'panel-' + name));
    
    if (name === 'console' && document.getElementById('autoscroll').checked) {
        const out = document.getElementById('console-output');
        out.scrollTop = out.scrollHeight;
    }
}

// ─── Options (Properties GUI) ───────────────────────────────────────────────
let rawPropertiesData = {};

async function loadPropertiesGUI() {
    try {
        const res = await fetch('/api/minecraft/properties');
        if (!res.ok) return;
        const d = await res.json();
        
        // Parse lines
        const lines = d.content.split('\n');
        rawPropertiesData = {};
        let html = '<div class="props-grid">';
        
        for (const line of lines) {
            if (line.trim().startsWith('#') || !line.includes('=')) continue;
            const [k, v] = line.split('=');
            const key = k.trim(), val = v.trim();
            rawPropertiesData[key] = val;
            
            // Build UI
            html += `<div class="prop-item">
                <label class="prop-label">${key}</label>
                ${getPropInputHtml(key, val)}
            </div>`;
        }
        html += '</div>';
        document.getElementById('props-gui-container').innerHTML = html;
    } catch {}
}

function getPropInputHtml(key, val) {
    const booleans = ['true', 'false'];
    
    // Explicit Dropdowns
    const dropdowns = {
        'difficulty': ['peaceful', 'easy', 'normal', 'hard'],
        'gamemode': ['survival', 'creative', 'adventure', 'spectator'],
        'level-type': ['default', 'flat', 'largeBiomes', 'amplified', 'buffet']
    };

    if (dropdowns[key]) {
        let optionsHtml = '';
        for (const opt of dropdowns[key]) {
            const selected = val.toLowerCase() === opt.toLowerCase() ? 'selected' : '';
            optionsHtml += `<option value="${opt}" ${selected}>${opt.charAt(0).toUpperCase() + opt.slice(1)}</option>`;
        }
        return `<select class="prop-input prop-select" data-key="${key}">${optionsHtml}</select>`;
    }

    if (booleans.includes(val.toLowerCase())) {
        const checked = val.toLowerCase() === 'true' ? 'checked' : '';
        return `<label class="toggle-switch">
            <input type="checkbox" data-key="${key}" ${checked}>
            <span class="toggle-slider"></span>
        </label>`;
    }
    
    if (!isNaN(val) && val !== '') {
        return `<input type="number" class="prop-input" data-key="${key}" value="${val}">`;
    }
    
    return `<input type="text" class="prop-input" data-key="${key}" value="${val}">`;
}

async function savePropertiesGUI() {
    const container = document.getElementById('props-gui-container');
    const inputs = container.querySelectorAll('input');
    
    for (const input of inputs) {
        const key = input.dataset.key;
        if (input.type === 'checkbox') {
            rawPropertiesData[key] = input.checked ? 'true' : 'false';
        } else {
            rawPropertiesData[key] = input.value;
        }
    }
    
    // Reconstruct file
    let newContent = '#Minecraft server properties\n';
    for (const [k, v] of Object.entries(rawPropertiesData)) {
        newContent += `${k}=${v}\n`;
    }
    
    try {
        const res = await fetch('/api/minecraft/properties', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ content: newContent })
        });
        if (res.ok) alert('Properties saved. Restart server to apply.');
        else alert('Failed to save properties.');
    } catch { alert('Error saving properties.'); }
}

// ─── Players Management & Stats ───────────────────────────────────────────────
function switchPlayerList(type, el) {
    document.querySelectorAll('.p-nav-item').forEach(i => i.classList.remove('active'));
    el.classList.add('active');
    currentPlayerListType = type;
    loadPlayerList();
}

async function loadPlayerList() {
    const container = document.getElementById('players-container');
    container.innerHTML = '<div style="padding:2rem;text-align:center;color:var(--text-dim)">Loading...</div>';
    try {
        const res = await fetch('/api/minecraft/players/' + currentPlayerListType);
        if (!res.ok) throw new Error();
        const players = await res.json();
        
        container.innerHTML = players.map(p => `
            <div class="player-row" style="cursor:pointer" onclick="openPlayerStats('${p.name}')">
                <div class="p-name">
                    <img class="p-avatar" src="https://minotar.net/helm/${p.name}/32.png" alt="" onerror="this.src='data:image/svg+xml;utf8,<svg width=32 height=32 xmlns=http://www.w3.org/2000/svg><rect width=32 height=32 fill=%23333/></svg>'">
                    ${p.name}
                </div>
                <button class="btn-xs btn-danger" onclick="event.stopPropagation(); removePlayer('${p.uuid || p.name}')">Remove</button>
            </div>
        `).join('') || '<div style="padding:2rem;text-align:center;color:var(--text-dim)">List is empty</div>';
    } catch {
        container.innerHTML = '<div style="padding:2rem;text-align:center;color:var(--text-dim)">Failed to load list.</div>';
    }
}

async function addPlayer() {
    const input = document.getElementById('player-add-name');
    const name = input.value.trim();
    if (!name) return;
    
    let cmd = '';
    if (currentPlayerListType === 'whitelist') cmd = `whitelist add ${name}`;
    if (currentPlayerListType === 'ops') cmd = `op ${name}`;
    if (currentPlayerListType === 'banned-players') cmd = `ban ${name}`;
    
    try {
        await fetch('/api/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ command: cmd })
        });
        input.value = '';
        setTimeout(loadPlayerList, 1000); 
    } catch { alert('Failed to add player'); }
}

async function removePlayer(id_or_name) {
    if (!confirm(`Remove ${id_or_name} from ${currentPlayerListType}?`)) return;
    
    let cmd = '';
    if (currentPlayerListType === 'whitelist') cmd = `whitelist remove ${id_or_name}`;
    if (currentPlayerListType === 'ops') cmd = `deop ${id_or_name}`;
    if (currentPlayerListType === 'banned-players') cmd = `pardon ${id_or_name}`;
    
    try {
        await fetch('/api/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ command: cmd })
        });
        setTimeout(loadPlayerList, 1000);
    } catch { alert('Failed to remove player'); }
}

async function openPlayerStats(name) {
    const modal = document.getElementById('player-stats-modal');
    const content = document.getElementById('ps-content');
    const title = document.getElementById('ps-title');
    
    title.textContent = `Stats for ${name}`;
    content.innerHTML = '<div style="text-align:center;color:var(--text-dim);padding:2rem">Fetching world data...</div>';
    modal.classList.add('show');
    
    try {
        const res = await fetch(`/api/minecraft/player/${name}/stats`);
        const data = await res.json();
        
        if (!res.ok) {
            content.innerHTML = `<div style="text-align:center;color:var(--red);padding:2rem">${data.error || 'Player not found in world data'}</div>`;
            return;
        }
        
        let invHtml = '<div class="inv-grid">';
        for (let i=0; i<36; i++) {
            const item = data.inventory.find(x => x.slot === i);
            if (item) invHtml += `<div class="inv-slot" title="${item.id} x${item.count}">
                <div class="inv-item">${item.id.replace('minecraft:','')}</div>
                <div class="inv-count">${item.count}</div>
            </div>`;
            else invHtml += `<div class="inv-slot empty"></div>`;
        }
        invHtml += '</div>';

        content.innerHTML = `
            <div style="display:flex;gap:2rem;margin-bottom:1.5rem">
                <img src="https://minotar.net/armor/body/${name}/100.png" style="border-radius:8px">
                <div style="flex:1;display:grid;grid-template-columns:1fr 1fr;gap:1rem">
                    <div class="glass" style="padding:1rem;border-radius:8px">
                        <div style="font-size:.75rem;color:var(--text-dim);text-transform:uppercase">Location</div>
                        <div class="mono" style="font-size:1.1rem;margin-top:.3rem">X:${Math.round(data.position.x)} Y:${Math.round(data.position.y)} Z:${Math.round(data.position.z)}</div>
                        <div style="font-size:.8rem;color:var(--text-muted);margin-top:.3rem">${data.dimension.replace('minecraft:','')}</div>
                    </div>
                    <div class="glass" style="padding:1rem;border-radius:8px">
                        <div style="font-size:.75rem;color:var(--text-dim);text-transform:uppercase">Vitals</div>
                        <div style="margin-top:.3rem">❤️ ${Math.round(data.health/2)}/10 &nbsp;&nbsp; 🍖 ${Math.round(data.food/2)}/10</div>
                        <div style="font-size:.8rem;color:var(--accent);margin-top:.3rem">XP Level ${data.xp}</div>
                    </div>
                </div>
            </div>
            <h4>Inventory</h4>
            ${invHtml}
        `;
    } catch {
        content.innerHTML = `<div style="text-align:center;color:var(--red);padding:2rem">Failed to load data</div>`;
    }
}

function closePlayerStats() {
    document.getElementById('player-stats-modal').classList.remove('show');
}

// ─── File Manager ───────────────────────────────────────────────
async function loadFiles() {
    try {
        const res = await fetch('/api/files/list?path=' + encodeURIComponent(currentFilePath));
        const files = await res.json();
        document.getElementById('file-path').textContent = '/' + currentFilePath;
        const list = document.getElementById('file-list');
        list.innerHTML = files.map(f => `
            <div class="file-row" onclick="${f.isDir ? `openDir('${f.name}')` : `openFile('${f.name}')`}">
                <span class="file-icon">${f.isDir ? '📁' : '📄'}</span>
                <span class="file-name">${f.name}</span>
                <span class="file-size">${f.isDir ? '' : fmtBytes(f.size)}</span>
            </div>`).join('') || '<div class="file-row" style="justify-content:center;color:var(--text-dim);cursor:default">Empty directory</div>';
    } catch {}
}

function openDir(name) { currentFilePath = currentFilePath ? currentFilePath + '/' + name : name; loadFiles(); }
function fileUp() { const parts = currentFilePath.split('/'); parts.pop(); currentFilePath = parts.join('/'); loadFiles(); }

async function openFile(name) {
    const fpath = currentFilePath ? currentFilePath + '/' + name : name;
    try {
        const res = await fetch('/api/files/read?path=' + encodeURIComponent(fpath));
        if (!res.ok) return;
        document.getElementById('editor-filename').textContent = name;
        document.getElementById('editor-content').value = await res.text();
        document.getElementById('file-editor').style.display = 'flex';
        document.getElementById('file-editor').dataset.path = fpath;
    } catch {}
}

async function saveFile() {
    const fpath = document.getElementById('file-editor').dataset.path;
    const content = document.getElementById('editor-content').value;
    try {
        await fetch('/api/files/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ path: fpath, content })
        });
        alert('File saved');
    } catch {}
}

function closeEditor() { document.getElementById('file-editor').style.display = 'none'; }

async function uploadFile(input) {
    if (!input.files[0]) return;
    const form = new FormData();
    form.append('file', input.files[0]);
    form.append('path', currentFilePath);
    try {
        await fetch('/api/files/upload', { method: 'POST', body: form });
        loadFiles();
    } catch {}
    input.value = '';
}

// ─── Backups ───────────────────────────────────────────────
async function loadBackups() {
    try {
        const res = await fetch('/api/backups');
        const backups = await res.json();
        document.getElementById('backup-items').innerHTML = backups.map(b => `
            <div class="backup-item">
                <span class="backup-name">${b.name}</span>
                <div class="backup-meta">
                    <span class="backup-size">${fmtBytes(b.size)}</span>
                    <button class="btn-xs btn-danger" onclick="deleteBackup('${b.name}')">Delete</button>
                </div>
            </div>`).join('') || '<div class="backup-item" style="justify-content:center;color:var(--text-dim)">No backups found</div>';
    } catch {}
}

async function deleteBackup(name) {
    if (!confirm(`Delete backup "${name}"?`)) return;
    await fetch(`/api/backups/${encodeURIComponent(name)}`, { method: 'DELETE' });
    loadBackups();
}

// ─── Power ───────────────────────────────────────────────
async function powerAction(action) {
    try {
        await fetch('/api/power', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action })
        });
        setTimeout(fetchStatus, 2000);
    } catch {}
}

// ─── Utility ───────────────────────────────────────────────
function copyText(text, btn) {
    navigator.clipboard.writeText(text).then(() => {
        const orig = btn.textContent;
        btn.textContent = '✓';
        setTimeout(() => btn.textContent = orig, 1500);
    });
}
