import { AnimatePresence, motion } from 'framer-motion';
import { ArrowRight, CheckCircle2, LockKeyhole, Server, ShieldCheck } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { ease, fadeIn, riseIn, spring, stagger } from '../lib/motion';
import Ambient from '../components/Ambient';

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: object) => void;
          renderButton: (element: HTMLElement, options: object) => void;
        };
      };
    };
    handleGoogleCredential?: (response: { credential: string }) => void;
  }
}

const HEADLINE: { word: string; grad?: boolean }[] = [
  { word: 'One' },
  { word: 'quiet' },
  { word: 'place' },
  { word: 'for' },
  { word: 'your' },
  { word: 'entire', grad: true },
  { word: 'server.', grad: true },
];

const FEATURES = [
  'Live container health',
  'Real-time server console',
  'Secure admin access',
];

export default function Login() {
  const { isAuthenticated, loading } = useAuth();
  const navigate = useNavigate();
  const googleBtnRef = useRef<HTMLDivElement>(null);
  const [loginError,       setLoginError]       = useState('');
  const [isLoggingIn,      setIsLoggingIn]      = useState(false);
  const [googleConfigured, setGoogleConfigured] = useState(true);

  useEffect(() => {
    if (!loading && isAuthenticated) navigate('/hub');
  }, [isAuthenticated, loading, navigate]);

  useEffect(() => {
    fetch('/api/config')
      .then(r => r.json())
      .then(cfg => {
        if (!cfg.googleClientId) { setGoogleConfigured(false); return; }

        window.handleGoogleCredential = async (response) => {
          setIsLoggingIn(true);
          setLoginError('');
          try {
            const res  = await fetch('/api/auth/google', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ credential: response.credential }),
            });
            const data = await res.json();
            if (res.ok && data.success) {
              window.location.href = '/hub';
            } else {
              setLoginError(data.error || 'Access denied. Contact the administrator.');
              setIsLoggingIn(false);
            }
          } catch {
            setLoginError('Network error. Please try again.');
            setIsLoggingIn(false);
          }
        };

        const init = () => {
          if (!window.google || !googleBtnRef.current) return;
          window.google.accounts.id.initialize({
            client_id: cfg.googleClientId,
            callback: window.handleGoogleCredential,
            auto_select: false,
            cancel_on_tap_outside: true,
          });
          window.google.accounts.id.renderButton(googleBtnRef.current, {
            theme: 'filled_black',
            size: 'large',
            width: 320,
            shape: 'rectangular',
            text: 'sign_in_with',
          });
        };

        const existing = document.getElementById('gsi-script');
        if (existing) { init(); }
        else {
          const s = document.createElement('script');
          s.id = 'gsi-script'; s.src = 'https://accounts.google.com/gsi/client';
          s.async = true; s.onload = init;
          document.head.appendChild(s);
        }
      })
      .catch(() => setGoogleConfigured(false));
  }, []);

  if (loading) {
    return (
      <div className="loading-screen">
        <span className="loading-dot" />
        <span>Checking your session…</span>
      </div>
    );
  }

  return (
    <div className="login-shell">
      <Ambient variant="auth" />

      {/* ── Left: hero copy ── */}
      <motion.section
        className="login-intro"
        variants={stagger(0.08, 0.09)}
        initial="hidden"
        animate="show"
      >
        {/* Brand */}
        <motion.div className="login-brand" variants={fadeIn}>
          <div className="login-brand-mark"><Server size={17} /></div>
          <div>
            <div className="login-brand-name">VPS Control</div>
            <div className="login-brand-sub">Private infrastructure</div>
          </div>
        </motion.div>

        <div className="login-intro-copy">
          <motion.p className="eyebrow" style={{ marginBottom: 20 }} variants={riseIn}>
            Operations console
          </motion.p>

          {/* Word-by-word headline */}
          <h1 className="login-headline">
            {HEADLINE.map(({ word, grad }, i) => (
              <motion.span
                key={word + i}
                className={`login-word${grad ? ' grad' : ''}`}
                initial={{ opacity: 0, y: '0.5em', filter: 'blur(8px)' }}
                animate={{ opacity: 1, y: 0,       filter: 'blur(0px)' }}
                transition={{ delay: 0.22 + i * 0.06, duration: 0.6, ease: ease.out }}
              >
                {word}
              </motion.span>
            ))}
          </h1>

          <motion.p className="login-subtitle" variants={riseIn}>
            Monitor containers, manage your Minecraft server, and stay in control —
            without the noise.
          </motion.p>

          <motion.ul className="login-features" variants={stagger(0.5, 0.08)}>
            {FEATURES.map(f => (
              <motion.li key={f} variants={riseIn}>
                <CheckCircle2 size={14} />
                {f}
              </motion.li>
            ))}
          </motion.ul>
        </div>

        <motion.div className="login-footer" variants={fadeIn}>
          rushiserver.duckdns.org <span>•</span> Private infrastructure portal
        </motion.div>
      </motion.section>

      {/* ── Right: auth card ── */}
      <motion.main
        className="login-card"
        initial={{ opacity: 0, y: 28, scale: 0.95, filter: 'blur(8px)' }}
        animate={{ opacity: 1, y: 0,  scale: 1,    filter: 'blur(0px)' }}
        transition={{ delay: 0.18, ...spring.modal }}
      >
        {/* Badge */}
        <div className="login-card-badge">
          <LockKeyhole size={11} />
          Authorized access only
        </div>

        <h2>Welcome back</h2>
        <p className="login-card-desc">
          Sign in with your approved Google account to access the control panel.
        </p>

        <div className="login-divider" />

        {/* Google button area */}
        <div className="login-provider">
          {isLoggingIn ? (
            <motion.div
              className="login-progress"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }}
            >
              <span className="loading-dot" />
              Verifying your account…
            </motion.div>
          ) : googleConfigured ? (
            <div ref={googleBtnRef} />
          ) : (
            <div className="provider-unavailable">
              <ShieldCheck size={15} />
              Google sign-in is not configured yet.
            </div>
          )}

          <AnimatePresence>
            {loginError && (
              <motion.div
                className="login-error"
                initial={{ opacity: 0, y: -6, height: 0 }}
                animate={{ opacity: 1, y: 0, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.25 }}
              >
                {loginError}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="login-security">
          <ShieldCheck size={13} />
          <span>Your session is encrypted and expires automatically after inactivity.</span>
        </div>

        <div className="login-card-footer">
          <span>Need access?</span>
          <span className="login-contact">
            Contact your admin <ArrowRight size={12} />
          </span>
        </div>
      </motion.main>
    </div>
  );
}
