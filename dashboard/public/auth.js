document.addEventListener('DOMContentLoaded', async () => {
    const isAuth = await checkAuth();
    if (isAuth) {
        redirectUser();
    } else {
        initParticles();
        initGoogleSignIn();
    }
});

function redirectUser() {
    if (currentUser.role === 'admin') {
        window.location.href = '/hub';
    } else {
        const allowed = currentUser.allowedContainers || [];
        if (allowed.length === 1 && allowed[0] === 'minecraft') {
            window.location.href = '/minecraft';
        } else {
            window.location.href = '/hub';
        }
    }
}

async function initGoogleSignIn() {
    try {
        const res = await fetch('/api/config');
        const config = await res.json();
        if (!config.googleClientId) {
            showLoginError('Google OAuth not configured on server.');
            return;
        }

        const waitForGoogle = () => new Promise((resolve) => {
            if (window.google?.accounts?.id) return resolve();
            const check = setInterval(() => {
                if (window.google?.accounts?.id) { clearInterval(check); resolve(); }
            }, 100);
            setTimeout(() => { clearInterval(check); resolve(); }, 5000);
        });

        await waitForGoogle();
        if (!window.google?.accounts?.id) {
            showLoginError('Google Sign-In library failed to load.');
            return;
        }

        google.accounts.id.initialize({
            client_id: config.googleClientId,
            callback: handleGoogleCredential,
            auto_select: false,
        });

        google.accounts.id.renderButton(
            document.getElementById('google-signin-btn'),
            { theme: 'filled_black', size: 'large', shape: 'pill', text: 'signin_with', width: 280 }
        );
    } catch (err) {
        showLoginError('Failed to initialize sign-in: ' + err.message);
    }
}

async function handleGoogleCredential(response) {
    try {
        const res = await fetch('/api/auth/google', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ credential: response.credential })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Login failed');
        currentUser = data.user;
        redirectUser();
    } catch (err) {
        showLoginError(err.message);
    }
}

function showLoginError(msg) {
    const el = document.getElementById('login-error-landing');
    if (el) { el.textContent = msg; el.classList.add('show'); }
}

function initParticles() {
    const canvas = document.getElementById('particle-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let particles = [];
    let w, h;
    const PARTICLE_COUNT = 60;
    const MAX_DIST = 120;

    function resize() {
        w = canvas.width = window.innerWidth;
        h = canvas.height = window.innerHeight;
    }
    resize();
    window.addEventListener('resize', resize);

    for (let i = 0; i < PARTICLE_COUNT; i++) {
        particles.push({
            x: Math.random() * w, y: Math.random() * h,
            vx: (Math.random() - .5) * .4, vy: (Math.random() - .5) * .4,
            r: Math.random() * 2 + 1, a: Math.random() * .4 + .1
        });
    }

    function draw() {
        ctx.clearRect(0, 0, w, h);
        for (let i = 0; i < particles.length; i++) {
            const p = particles[i];
            p.x += p.vx; p.y += p.vy;
            if (p.x < 0 || p.x > w) p.vx *= -1;
            if (p.y < 0 || p.y > h) p.vy *= -1;

            ctx.beginPath();
            ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(108, 92, 231, ${p.a})`;
            ctx.fill();

            for (let j = i + 1; j < particles.length; j++) {
                const p2 = particles[j];
                const dx = p.x - p2.x, dy = p.y - p2.y;
                const dist = Math.sqrt(dx * dx + dy * dy);
                if (dist < MAX_DIST) {
                    ctx.beginPath();
                    ctx.moveTo(p.x, p.y);
                    ctx.lineTo(p2.x, p2.y);
                    ctx.strokeStyle = `rgba(108, 92, 231, ${.12 * (1 - dist / MAX_DIST)})`;
                    ctx.lineWidth = .5;
                    ctx.stroke();
                }
            }
        }
        requestAnimationFrame(draw);
    }
    draw();
}
