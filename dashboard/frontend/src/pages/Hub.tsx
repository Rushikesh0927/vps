import { motion } from 'framer-motion';
import {
  Activity, ArrowUpRight, Cpu, HardDrive, LogOut, MemoryStick, Server, Sparkles,
} from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { preloadMinecraftOverview } from '../lib/minecraftOverview';
import { cardIn, riseIn, spring, stagger } from '../lib/motion';
import Ambient from '../components/Ambient';
import SpotlightCard from '../components/SpotlightCard';
import Ticker from '../components/Ticker';
import { LiveDot, Meter } from '../components/Live';

interface Container {
  name: string; state: string; status: string; image: string;
  cpu: number; memUsed: number; memLimit: number; memPercent: number;
}
interface SystemStats {
  cpu:    { count: number; percent: number; model: string };
  memory: { total: number; used: number; free: number; percent: number };
  disk:   { total: number; used: number; free: number; percent: number };
}

function fmtBytes(b: number) {
  if (!b) return '0 B';
  const u = ['B','KB','MB','GB','TB'];
  const i = Math.min(Math.floor(Math.log(b) / Math.log(1024)), u.length - 1);
  return `${(b / 1024 ** i).toFixed(1)} ${u[i]}`;
}
function initial(name: string) { return name.charAt(0).toUpperCase(); }
function toneFor(pct: number): 'good' | 'warn' | 'bad' {
  return pct > 85 ? 'bad' : pct > 65 ? 'warn' : 'good';
}
function greeting() {
  const h = new Date().getHours();
  return h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
}

export default function Hub() {
  const [containers, setContainers] = useState<Container[]>([]);
  const [system,     setSystem]     = useState<SystemStats | null>(null);
  const navigate = useNavigate();
  const { user } = useAuth();

  const fetchContainers = useCallback(() => {
    fetch('/api/containers')
      .then(r => r.json())
      .then(d => { if (Array.isArray(d)) setContainers(d); })
      .catch(() => {});
  }, []);

  const fetchSystem = useCallback(() => {
    if (user?.role !== 'admin') return;
    fetch('/api/system/stats')
      .then(r => r.json())
      .then(d => { if (d.cpu) setSystem(d); })
      .catch(() => {});
  }, [user]);

  useEffect(() => {
    fetchContainers();
    fetchSystem();
    preloadMinecraftOverview();
    const t1 = window.setInterval(fetchContainers, 10_000);
    const t2 = window.setInterval(fetchSystem, 15_000);
    return () => { clearInterval(t1); clearInterval(t2); };
  }, [fetchContainers, fetchSystem]);

  const signOut = async () => {
    try { await fetch('/api/logout', { method: 'POST' }); } catch {}
    window.location.href = '/';
  };

  const running   = containers.filter(c => c.state === 'running').length;
  const firstName = user?.name?.split(' ')[0] || 'there';

  const healthCards = system ? [
    { label: 'CPU',    value: system.cpu.percent,    detail: `${system.cpu.count} host cores`,                                              Icon: Cpu        },
    { label: 'Memory', value: system.memory.percent, detail: `${fmtBytes(system.memory.used)} / ${fmtBytes(system.memory.total)} used`,     Icon: MemoryStick },
    { label: 'Disk',   value: system.disk.percent,   detail: `${fmtBytes(system.disk.used)} / ${fmtBytes(system.disk.total)} used`,         Icon: HardDrive   },
  ] : [];

  return (
    <div className="app-shell">
      <Ambient />

      {/* ── Top bar ── */}
      <motion.header
        className="app-topbar"
        initial={{ y: -60, opacity: 0 }}
        animate={{ y: 0,   opacity: 1 }}
        transition={spring.drift}
      >
        <div className="topbar-left">
          <div className="brand-mark"><Server size={16} /></div>
          <div>
            <div className="brand-name">VPS Control</div>
            <div className="brand-subtitle">Private infrastructure</div>
          </div>
        </div>

        <div className="topbar-actions">
          <div className="user-chip">
            {user?.picture
              ? <img className="user-avatar" src={user.picture} alt="" />
              : (
                <div className="user-avatar avatar-fallback">
                  {firstName[0]?.toUpperCase()}
                </div>
              )}
            <span>{user?.name || 'Administrator'}</span>
          </div>
          <motion.button
            className="btn"
            onClick={signOut}
            whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }}
            transition={spring.press}
          >
            <LogOut size={13} /> Sign out
          </motion.button>
        </div>
      </motion.header>

      {/* ── Page body ── */}
      <motion.main
        className="hub-page"
        variants={stagger(0.06, 0.08)}
        initial="hidden"
        animate="show"
      >
        {/* Intro */}
        <motion.section className="hub-intro" variants={riseIn}>
          <div>
            <p className="eyebrow" style={{ marginBottom: 12 }}>Private infrastructure</p>
            <h1>{greeting()}, {firstName}.</h1>
            <span className="hub-intro-desc">
              Your services are monitored and ready. Everything updates in real time.
            </span>
          </div>
          <motion.div
            className="hub-stat-bubble"
            whileHover={{ y: -3, scale: 1.02 }}
            transition={spring.lift}
          >
            <span className="hub-stat-icon"><Activity size={16} /></span>
            <div>
              <strong className="tabular">
                <Ticker value={running} /> of {containers.length || '—'} online
              </strong>
              <small>Services reporting normally</small>
            </div>
          </motion.div>
        </motion.section>

        {/* System health — admin only */}
        {user?.role === 'admin' && (
          <motion.section className="hub-section" variants={riseIn}>
            <div className="hub-section-title">
              <div>
                <p className="eyebrow">System health</p>
                <h2>Host resources</h2>
              </div>
              <aside>
                <LiveDot state="online" />
                Updates every 15 s
              </aside>
            </div>

            <motion.div
              className="hub-health-grid"
              variants={stagger(0, 0.07)} initial="hidden" animate="show"
            >
              {healthCards.length
                ? healthCards.map(({ label, value, detail, Icon }) => (
                  <motion.div key={label} variants={cardIn}>
                    <SpotlightCard
                      className="hub-health-card"
                      glow="rgba(139,92,246,.14)"
                    >
                      <div className="hub-health-row">
                        <span className="hub-health-icon"><Icon size={14} /></span>
                        <span className="hub-health-label">{label}</span>
                      </div>
                      <div className="hub-health-val tabular">
                        <Ticker value={value} decimals={1} suffix="%" />
                      </div>
                      <Meter percent={value} tone={toneFor(value)} />
                      <p className="hub-health-detail">{detail}</p>
                    </SpotlightCard>
                  </motion.div>
                ))
                : (
                  <div className="hub-health-placeholder shimmer">
                    <Sparkles size={15} /> Reading host telemetry…
                  </div>
                )}
            </motion.div>
          </motion.section>
        )}

        {/* Services */}
        <motion.section className="hub-section" variants={riseIn}>
          <div className="hub-section-title">
            <div>
              <p className="eyebrow">Workloads</p>
              <h2>Services</h2>
            </div>
            <aside>
              <span className="tabular">{running}</span> running
            </aside>
          </div>

          {containers.length
            ? (
              <motion.div
                className="hub-services"
                variants={stagger(0, 0.07)} initial="hidden" animate="show"
              >
                {containers.map(c => {
                  const on  = c.state === 'running';
                  const isMC = c.name.toLowerCase() === 'minecraft';
                  return (
                    <motion.div key={c.name} variants={cardIn}>
                      <SpotlightCard
                        className="hub-service"
                        interactive={isMC}
                        glow={isMC ? 'rgba(139,92,246,.20)' : 'rgba(255,255,255,.05)'}
                        onMouseEnter={() => isMC && preloadMinecraftOverview()}
                        onFocus={()       => isMC && preloadMinecraftOverview()}
                        onClick={isMC ? () => navigate('/minecraft') : undefined}
                      >
                        <header>
                          <span className="hub-service-icon">{initial(c.name)}</span>
                          <span className={`hub-service-status ${on ? 'online' : 'offline'}`}>
                            <LiveDot state={on ? 'online' : 'offline'} />
                            {c.state}
                          </span>
                        </header>

                        <div className="hub-service-name">
                          <h3>{c.name}</h3>
                          <p>{c.image}</p>
                        </div>

                        {on
                          ? (
                            <div className="hub-service-metrics">
                              <Metric label="CPU"    value={`${c.cpu.toFixed(1)}%`}  pct={c.cpu} />
                              <Metric label="Memory" value={fmtBytes(c.memUsed)}     pct={c.memPercent} />
                            </div>
                          )
                          : <div className="hub-service-offline">Service is currently stopped.</div>}

                        <footer>
                          {isMC
                            ? <><span>Open workspace</span><ArrowUpRight size={13} className="hub-service-arrow" /></>
                            : <span>{c.status}</span>}
                        </footer>
                      </SpotlightCard>
                    </motion.div>
                  );
                })}
              </motion.div>
            )
            : (
              <div className="hub-services-loading">
                <Sparkles size={16} />
                <span>Finding your services…</span>
              </div>
            )}
        </motion.section>
      </motion.main>
    </div>
  );
}

function Metric({ label, value, pct }: { label: string; value: string; pct: number }) {
  return (
    <div className="hub-service-metric">
      <label><span>{label}</span><b className="tabular">{value}</b></label>
      <Meter percent={pct} tone={toneFor(pct)} />
    </div>
  );
}
