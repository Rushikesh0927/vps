let currentUser = null;

async function checkAuth() {
    try {
        const res = await fetch('/api/auth/me');
        const data = await res.json();
        if (data.user) {
            currentUser = data.user;
            return true;
        }
    } catch {}
    return false;
}

function fmtBytes(b) {
    if (!b || b <= 0) return '0 B';
    const u = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.min(Math.floor(Math.log(b) / Math.log(1024)), u.length - 1);
    return (b / Math.pow(1024, i)).toFixed(i > 1 ? 1 : 0) + ' ' + u[i];
}

async function logout() {
    await fetch('/api/logout', { method: 'POST' });
    currentUser = null;
    window.location.href = '/';
}
