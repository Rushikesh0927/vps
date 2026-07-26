let allContainerNames = [];
let currentContainersData = [];

document.addEventListener('DOMContentLoaded', async () => {
    const isAuth = await checkAuth();
    if (!isAuth) {
        window.location.href = '/';
        return;
    }

    updateUserChips();

    if (currentUser.role === 'admin') {
        document.getElementById('system-overview').style.display = 'grid';
        document.getElementById('user-management-section').style.display = 'block';
        loadSystemStats();
        loadContainers();
        loadUsers();
        setInterval(loadSystemStats, 10000);
        setInterval(loadContainers, 15000);
    } else {
        loadContainers();
        setInterval(loadContainers, 15000);
    }
});

function updateUserChips() {
    if (!currentUser) return;
    const nameEl = document.getElementById('hub-user-name');
    const avatarEl = document.getElementById('hub-user-avatar');
    if (nameEl) nameEl.textContent = currentUser.name || currentUser.email.split('@')[0];
    if (avatarEl && currentUser.picture) { avatarEl.src = currentUser.picture; avatarEl.style.display = 'block'; }
}

function openContainerDashboard(name) {
    if (name === 'minecraft') {
        window.location.href = '/minecraft';
    }
}

// ─── System Stats ───────────────────────────────────────────────
function setRing(id, percent) {
    const ring = document.getElementById(id);
    if (!ring) return;
    const circumference = 2 * Math.PI * 42; // r=42
    const offset = circumference * (1 - Math.min(percent, 100) / 100);
    ring.style.strokeDashoffset = offset;
}

async function loadSystemStats() {
    if (currentUser?.role !== 'admin') return;
    try {
        const res = await fetch('/api/system/stats');
        if (!res.ok) return;
        const s = await res.json();

        // CPU
        document.getElementById('val-cpu').textContent = s.cpu.percent + '%';
        document.getElementById('sub-cpu').textContent = s.cpu.count + ' cores';
        setRing('ring-cpu', s.cpu.percent);

        // RAM
        document.getElementById('val-ram').textContent = s.memory.percent + '%';
        document.getElementById('sub-ram').textContent = fmtBytes(s.memory.used) + ' / ' + fmtBytes(s.memory.total);
        setRing('ring-ram', s.memory.percent);

        // Disk
        const diskPct = s.disk.total > 0 ? Math.round(s.disk.used / s.disk.total * 100) : s.disk.percent;
        document.getElementById('val-disk').textContent = diskPct + '%';
        document.getElementById('sub-disk').textContent = fmtBytes(s.disk.used) + ' / ' + fmtBytes(s.disk.total);
        setRing('ring-disk', diskPct);

        // GDrive
        const gdPct = s.gdrive.total > 0 ? Math.round(s.gdrive.used / s.gdrive.total * 1000) / 10 : 0;
        document.getElementById('val-gdrive').textContent = gdPct + '%';
        document.getElementById('sub-gdrive').textContent = fmtBytes(s.gdrive.used) + ' / ' + fmtBytes(s.gdrive.total);
        setRing('ring-gdrive', gdPct);
    } catch {}
}

async function clearCache(btn) {
    if (!confirm("This will clear the host system's file cache, freeing up unused RAM. Running processes will NOT be affected. Continue?")) return;
    const orig = btn.textContent;
    btn.textContent = 'Clearing...';
    btn.disabled = true;
    try {
        await fetch('/api/system/clearcache', { method: 'POST' });
        btn.textContent = 'Cleared!';
        setTimeout(loadSystemStats, 2000);
    } catch {
        btn.textContent = 'Error';
    }
    setTimeout(() => { btn.textContent = orig; btn.disabled = false; }, 3000);
}

// ─── Breakdowns ───────────────────────────────────────────────
async function showBreakdown(type) {
    const modal = document.getElementById('breakdown-modal');
    const title = document.getElementById('breakdown-title');
    const list = document.getElementById('breakdown-list');
    modal.classList.add('show');
    list.innerHTML = '<div style="text-align:center;padding:2rem;color:var(--text-dim)">Loading breakdown...</div>';

    if (type === 'cpu') {
        title.textContent = 'CPU Usage by Container';
        const sorted = [...currentContainersData].sort((a, b) => b.cpu - a.cpu);
        list.innerHTML = sorted.map(c => `
            <div class="bd-row">
                <span class="bd-name">${c.name}</span>
                <div class="bd-bar-wrap"><div class="bd-bar" style="width:${Math.min(c.cpu, 100)}%"></div></div>
                <span class="bd-val mono">${c.cpu}%</span>
            </div>
        `).join('') || '<div class="bd-empty">No running containers</div>';
    } else if (type === 'ram') {
        title.textContent = 'RAM Usage by Container';
        const sorted = [...currentContainersData].sort((a, b) => b.memUsed - a.memUsed);
        list.innerHTML = sorted.map(c => `
            <div class="bd-row">
                <span class="bd-name">${c.name}</span>
                <div class="bd-bar-wrap"><div class="bd-bar bar-ram" style="width:${c.memPercent}%"></div></div>
                <span class="bd-val mono">${fmtBytes(c.memUsed)}</span>
            </div>
        `).join('') || '<div class="bd-empty">No running containers</div>';
    } else if (type === 'disk') {
        title.textContent = 'Disk Usage by Directory';
        try {
            const res = await fetch('/api/system/disk-breakdown');
            const data = await res.json();
            list.innerHTML = data.map(d => `
                <div class="bd-row">
                    <span class="bd-name">${d.path}</span>
                    <span class="bd-val mono">${d.size}</span>
                </div>
            `).join('') || '<div class="bd-empty">No data available</div>';
        } catch {
            list.innerHTML = '<div class="bd-empty">Failed to load disk breakdown</div>';
        }
    }
}

function closeBreakdown() {
    document.getElementById('breakdown-modal').classList.remove('show');
}

// ─── Containers ───────────────────────────────────────────────
async function loadContainers() {
    try {
        const res = await fetch('/api/containers');
        if (!res.ok) return;
        const containers = await res.json();
        currentContainersData = containers;
        allContainerNames = containers.map(c => c.name);
        const grid = document.getElementById('container-grid');
        if (!grid) return;

        grid.innerHTML = containers.map(c => {
            const isRunning = c.state === 'running';
            const stateClass = c.state || 'exited';
            const icon = c.name === 'minecraft' ? '🎮' : c.name === 'dashboard' ? '📊' : c.name === 'cloudflared' ? '☁️' : '📦';
            const clickable = c.name === 'minecraft' ? `onclick="openContainerDashboard('minecraft')"` : '';
            const cursorClass = c.name === 'minecraft' ? '' : 'style="cursor:default"';

            return `
                <div class="ct-card" ${clickable} ${cursorClass}>
                    <div class="ct-card-head">
                        <span class="ct-name">${icon} ${c.name}</span>
                        <span class="ct-state ${stateClass}">${c.state}</span>
                    </div>
                    <div class="ct-stats">
                        <div class="ct-stat">CPU<br><span class="ct-stat-val">${isRunning ? c.cpu + '%' : '—'}</span></div>
                        <div class="ct-stat">RAM<br><span class="ct-stat-val">${isRunning ? fmtBytes(c.memUsed) : '—'}</span></div>
                    </div>
                    <div class="ct-image">${c.image}</div>
                </div>`;
        }).join('');
    } catch {}
}

// ─── User Management ───────────────────────────────────────────────
async function loadUsers() {
    if (currentUser?.role !== 'admin') return;
    try {
        const res = await fetch('/api/users');
        if (!res.ok) return;
        const users = await res.json();
        const tbody = document.getElementById('users-tbody');
        if (!tbody) return;

        tbody.innerHTML = users.map(u => {
            const containers = (u.allowedContainers || []).map(c =>
                `<span class="container-tag">${c === '*' ? 'All' : c}</span>`
            ).join('');
            const lastLogin = u.lastLogin ? new Date(u.lastLogin).toLocaleDateString() : 'Never';
            const isMe = u.email === currentUser.email;

            return `<tr>
                <td><div class="user-email">${u.name || u.email.split('@')[0]}</div><div class="user-email-sub">${u.email}</div></td>
                <td><span class="role-badge ${u.role}">${u.role}</span></td>
                <td><div class="container-tags">${containers || '<span class="container-tag">None</span>'}</div></td>
                <td style="color:var(--text-dim);font-size:.82rem">${lastLogin}</td>
                <td>${isMe ? '<span style="color:var(--text-muted);font-size:.78rem">You</span>' :
                    `<button class="btn-sm btn-ghost" onclick="editUser('${u.id}','${u.email}','${u.role}',${JSON.stringify(JSON.stringify(u.allowedContainers))})">Edit</button>
                     <button class="btn-sm btn-danger" onclick="deleteUser('${u.id}','${u.email}')">Remove</button>`
                }</td>
            </tr>`;
        }).join('');
    } catch {}
}

function showAddUserModal() {
    document.getElementById('modal-title').textContent = 'Add User';
    document.getElementById('modal-email').value = '';
    document.getElementById('modal-email').disabled = false;
    document.getElementById('modal-role').value = 'user';
    document.getElementById('modal-user-id').value = '';
    renderContainerCheckboxes([]);
    document.getElementById('modal-overlay').classList.add('show');
}

function editUser(id, email, role, containersJson) {
    document.getElementById('modal-title').textContent = 'Edit User';
    document.getElementById('modal-email').value = email;
    document.getElementById('modal-email').disabled = true;
    document.getElementById('modal-role').value = role;
    document.getElementById('modal-user-id').value = id;
    const containers = JSON.parse(containersJson);
    renderContainerCheckboxes(containers);
    document.getElementById('modal-overlay').classList.add('show');
}

function renderContainerCheckboxes(selected) {
    const wrap = document.getElementById('modal-containers');
    const names = allContainerNames.length > 0 ? allContainerNames : ['minecraft', 'dashboard', 'cloudflared'];
    wrap.innerHTML = names.map(n =>
        `<label><input type="checkbox" value="${n}" ${selected.includes(n) || selected.includes('*') ? 'checked' : ''}> ${n}</label>`
    ).join('');
}

function closeModal() {
    document.getElementById('modal-overlay').classList.remove('show');
}

async function saveUser() {
    const id = document.getElementById('modal-user-id').value;
    const email = document.getElementById('modal-email').value.trim();
    const role = document.getElementById('modal-role').value;
    const checkboxes = document.querySelectorAll('#modal-containers input[type="checkbox"]:checked');
    const allowedContainers = Array.from(checkboxes).map(cb => cb.value);

    try {
        const url = id ? `/api/users/${id}` : '/api/users';
        const method = id ? 'PUT' : 'POST';
        const body = id ? { role, allowedContainers } : { email, role, allowedContainers };

        const res = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error);
        closeModal();
        loadUsers();
    } catch (err) {
        alert('Error: ' + err.message);
    }
}

async function deleteUser(id, email) {
    if (!confirm(`Remove ${email}? They will lose access.`)) return;
    try {
        const res = await fetch(`/api/users/${id}`, { method: 'DELETE' });
        if (!res.ok) { const d = await res.json(); throw new Error(d.error); }
        loadUsers();
    } catch (err) { alert('Error: ' + err.message); }
}
