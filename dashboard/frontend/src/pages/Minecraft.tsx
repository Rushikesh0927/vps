import { AnimatePresence, motion } from 'framer-motion';
import {
  Activity, ArrowLeft, Check, ChevronRight, Clock3, Copy, Cpu,
  Database, File, FileText, Folder, Gamepad2, HardDrive, MemoryStick,
  MinusCircle, Play, Plus, RefreshCw, Save, Shield, Square, Terminal,
  Trash2, Upload, Users,
} from 'lucide-react';
import {
  useCallback, useEffect, useRef, useState, type ReactNode,
} from 'react';
import {
  Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts';
import { toast } from 'sonner';
import { useNavigate } from 'react-router-dom';
import {
  getCachedMinecraftOverview,
  loadMinecraftOverview,
  type MinecraftOverview,
} from '../lib/minecraftOverview';
import { cardIn, pageIn, riseIn, spring, stagger } from '../lib/motion';
import Ambient from '../components/Ambient';
import SpotlightCard from '../components/SpotlightCard';
import Ticker from '../components/Ticker';
import { LiveDot } from '../components/Live';

/* ─── Types ─────────────────────────────────────────────────── */
type Tab = 'overview' | 'console' | 'players' | 'files' | 'backups' | 'options';
interface Pt { time: string; cpu: number; memory: number; }
interface PlayerEntry { uuid: string; name: string; }
interface FileEntry { name: string; isDir: boolean; size: number; }
interface BackupEntry { name: string; size: number; modified: string; }

/* ─── Helpers ────────────────────────────────────────────────── */
function fmtUptime(startedAt: string | null) {
  if (!startedAt) return '—';
  const s = Math.max(0, Math.floor((Date.now() - new Date(startedAt).getTime()) / 1000));
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`;
}
function fmtGiB(bytes: number) { return `${(bytes / 1024 ** 3).toFixed(1)} GB`; }
function fmtSize(bytes: number) {
  if (!bytes) return '0 B';
  const u = ['B', 'KB', 'MB', 'GB'];
  const i = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), u.length - 1);
  return `${(bytes / 1024 ** i).toFixed(1)} ${u[i]}`;
}
function mkPoint(d: MinecraftOverview): Pt {
  return {
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
    cpu: d.cpuPercent,
    memory: d.memPercent,
  };
}

/* ─── Nav config ─────────────────────────────────────────────── */
const TABS: { key: Tab; label: string; Icon: any }[] = [
  { key: 'overview', label: 'Overview',  Icon: Activity  },
  { key: 'console',  label: 'Console',   Icon: Terminal  },
  { key: 'players',  label: 'Players',   Icon: Users     },
  { key: 'files',    label: 'Files',     Icon: Folder    },
  { key: 'backups',  label: 'Backups',   Icon: Database  },
  { key: 'options',  label: 'Options',   Icon: HardDrive },
];


/* ════════════════════════════════════════════════════════════════
   MAIN COMPONENT
   ════════════════════════════════════════════════════════════════ */
export default function Minecraft() {
  const navigate = useNavigate();
  const cached   = getCachedMinecraftOverview();

  /* overview polling */
  const [overview,   setOverview]   = useState<MinecraftOverview | null>(cached);
  const [telemetry,  setTelemetry]  = useState<Pt[]>(cached ? [mkPoint(cached)] : []);
  const [refreshing, setRefreshing] = useState(!cached);
  const [powerBusy,  setPowerBusy]  = useState(false);
  const [copied,     setCopied]     = useState(false);

  /* console */
  const [tab,         setTab]         = useState<Tab>('overview');
  const [wsConnected, setWsConnected] = useState(false);
  const [logs,        setLogs]        = useState<{ time: string; text: string }[]>([]);
  const logsEnd = useRef<HTMLDivElement>(null);

  /* ── data fetching ── */
  const refresh = useCallback(async () => {
    try {
      const d = await loadMinecraftOverview();
      setOverview(d);
      setTelemetry(prev => [...prev, mkPoint(d)].slice(-30));
    } catch { /* keep snapshot */ }
    finally { setRefreshing(false); }
  }, []);

  useEffect(() => {
    void refresh();
    const t = setInterval(() => void refresh(), 3000);
    return () => clearInterval(t);
  }, [refresh]);

  /* ── WebSocket ── */
  useEffect(() => {
    const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
    let gone = false; let retry: ReturnType<typeof setTimeout> | undefined; let ws: WebSocket | null = null;
    const connect = () => {
      if (gone) return;
      ws = new WebSocket(`${proto}//${location.host}/api/logs/stream`);
      ws.onopen    = () => setWsConnected(true);
      ws.onclose   = () => { setWsConnected(false); if (!gone) retry = setTimeout(connect, 3000); };
      ws.onerror   = () => ws?.close();
      ws.onmessage = e => {
        const text = String(e.data).trim(); if (!text) return;
        const time = new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
        setLogs(prev => [...prev, { time, text }].slice(-250));
      };
    };
    connect();
    return () => { gone = true; clearTimeout(retry); ws?.close(); };
  }, []);

  useEffect(() => {
    if (tab === 'console') logsEnd.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs, tab]);

  /* ── power ── */
  const power = async (action: 'start' | 'stop') => {
    setPowerBusy(true);
    try {
      const res = await fetch('/api/power', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action }) });
      if (!res.ok) throw new Error('Failed to ' + action);
      toast.success(`Server ${action} command sent`);
      setTimeout(() => void refresh(), 900);
    } catch (err: any) {
      toast.error(err.message);
    } finally { setPowerBusy(false); }
  };

  const copyIp = (ip: string) => {
    void navigator.clipboard.writeText(ip);
    setCopied(true); setTimeout(() => setCopied(false), 1600);
    toast.success('IP address copied to clipboard');
  };

  const sendCmd = (cmd: string) => {
    if (!cmd.trim()) return;
    void fetch('/api/command', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ command: cmd }) });
  };

  const status   = overview?.status ?? 'starting';
  const isOnline = status === 'online';
  const busy     = powerBusy || refreshing;

  const tooltipContent = ({ active, payload }: any) =>
    active && payload?.length ? (
      <div className="telemetry-tooltip">
        {payload.map((p: any) => (
          <div key={p.name}><span>{p.name}</span><strong>{Number(p.value).toFixed(1)}%</strong></div>
        ))}
      </div>
    ) : null;

  /* ══════════════════════════════════════════════════════════════
     RENDER
     ══════════════════════════════════════════════════════════════ */
  return (
    <div className="mc-shell">
      <Ambient />

      {/* ── Sidebar ── */}
      <motion.aside className="mc-sidebar"
        initial={{ x: -48, opacity: 0 }} animate={{ x: 0, opacity: 1 }} transition={spring.drift}
      >
        <button className="mc-brand" onClick={() => navigate('/hub')}>
          <span className="mc-brand-mark"><Gamepad2 size={16} /></span>
          <span><strong>VPS Control</strong><small>Game services</small></span>
        </button>

        <div className="mc-server-card">
          <div className="mc-server-icon">M</div>
          <div><p>Minecraft</p><span>Java · 1.21.1</span></div>
          <LiveDot state={status as 'online' | 'offline' | 'starting'} />
        </div>

        <nav className="mc-nav" aria-label="Sections">
          {TABS.map(({ key, label, Icon }) => (
            <button key={key}
              className={tab === key ? 'active' : ''}
              onClick={() => setTab(key)}
              aria-current={tab === key ? 'page' : undefined}
            >
              {tab === key && <motion.span layoutId="mc-pill" className="mc-tab-pill" transition={spring.glide} />}
              <Icon size={14} />
              {label}
              {key === 'console' && <span className={`ws-dot${wsConnected ? ' connected' : ''}`} />}
            </button>
          ))}
        </nav>

        <div className="mc-sidebar-bottom">
          <div className="mc-allocation">
            <span>Allocated</span>
            <strong>{overview?.cpuCores ?? 2} vCPU · {overview ? fmtGiB(overview.memLimit) : '6.0 GB'}</strong>
          </div>
          <motion.button className="mc-button primary" disabled={busy || isOnline}
            onClick={() => power('start')} whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
            <Play size={13} /> Start
          </motion.button>
          <motion.button className="mc-button danger" disabled={busy || !overview?.running}
            onClick={() => power('stop')} whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
            <Square size={12} /> Stop
          </motion.button>
          <button className="mc-back" onClick={() => navigate('/hub')}><ArrowLeft size={12} /> All services</button>
        </div>
      </motion.aside>

      {/* ── Main ── */}
      <main className="mc-main">
        <motion.header className="mc-topbar"
          initial={{ y: -12, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.1, ...spring.lift }}
        >
          <div className="mc-crumb">
            <span>Services</span><ChevronRight size={12} /><b>Minecraft</b>
          </div>
          <div className="mc-topbar-right">
            <span className="mc-refresh">{refreshing ? 'Refreshing…' : 'Live'} <LiveDot state="online" /></span>
            {overview?.serverIp && (
              <motion.button className="mc-ip" onClick={() => copyIp(overview.serverIp)}
                whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
                {copied ? <Check size={12} /> : <Copy size={12} />}
                {copied ? 'Copied!' : overview.serverIp}
              </motion.button>
            )}
          </div>
        </motion.header>

        <div className="mc-content">
          <AnimatePresence mode="wait">
            {tab === 'overview' && (
              <OverviewTab key="ov" overview={overview} telemetry={telemetry} status={status}
                isOnline={isOnline} refreshing={refreshing} tooltipContent={tooltipContent} copyIp={copyIp} />
            )}
            {tab === 'console' && (
              <ConsoleTab key="con" logs={logs} logsEnd={logsEnd} wsConnected={wsConnected} sendCmd={sendCmd} />
            )}
            {tab === 'players' && <PlayersTab key="pl" />}
            {tab === 'files'   && <FilesTab   key="fi" />}
            {tab === 'backups' && <BackupsTab key="bk" />}
            {tab === 'options' && <OptionsTab key="op" />}
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}


/* ════════════════════════════════════════════════════════════════
   OVERVIEW TAB
   ════════════════════════════════════════════════════════════════ */
function OverviewTab({ overview, telemetry, status, isOnline, refreshing, tooltipContent, copyIp }: {
  overview: MinecraftOverview | null; telemetry: Pt[]; status: string;
  isOnline: boolean; refreshing: boolean; tooltipContent: any; copyIp: (ip: string) => void;
}) {
  return (
    <motion.section key="ov" variants={pageIn} initial="hidden" animate="show" exit="exit">
      {/* page heading */}
      <div className="mc-page-heading">
        <div><span>Live server</span><h1>Minecraft runtime</h1></div>
        <div className={`mc-status ${status}`}>
          <LiveDot state={status as 'online' | 'offline' | 'starting'} />
          {status === 'online' ? 'Online' : status === 'offline' ? 'Offline' : 'Starting up'}
        </div>
      </div>

      {/* status banner */}
      <motion.div className={`mc-status-banner ${status}`} variants={cardIn} initial="hidden" animate="show">
        <div className="mc-status-banner-left">
          <div className="mc-status-banner-dot" />
          <div>
            <div className="mc-status-banner-text">
              {isOnline ? 'Server is running' : status === 'offline' ? 'Server is offline' : 'Server is starting up…'}
            </div>
            <div className="mc-status-banner-sub">
              {isOnline
                ? `${overview?.players ?? 0} of ${overview?.maxPlayers ?? 10} players connected · Uptime ${fmtUptime(overview?.uptime ?? null)}`
                : 'Use the Start button in the sidebar to bring the server online.'}
            </div>
          </div>
        </div>
        {overview?.serverIp && (
          <div className="mc-status-banner-actions">
            <motion.button className="btn" onClick={() => copyIp(overview.serverIp)}
              whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
              <Copy size={12} /> {overview.serverIp}
            </motion.button>
            {overview.bedrockIp && (
              <motion.button className="btn" onClick={() => copyIp(overview.bedrockIp!)}
                whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
                <Copy size={12} /> Bedrock
              </motion.button>
            )}
          </div>
        )}
      </motion.div>

      {/* server info grid */}
      <motion.div className="mc-server-info-grid" variants={stagger(0, 0.06)} initial="hidden" animate="show">
        <motion.div variants={cardIn}>
          <SpotlightCard className="mc-info-card" glow="rgba(139,92,246,.1)">
            <div className="mc-info-icon"><Users size={16} /></div>
            <div>
              <div className="mc-info-label">Players</div>
              <div className="mc-info-value tabular">
                {overview ? `${overview.players} / ${overview.maxPlayers}` : '— / —'}
              </div>
            </div>
          </SpotlightCard>
        </motion.div>
        <motion.div variants={cardIn}>
          <SpotlightCard className="mc-info-card" glow="rgba(52,211,153,.1)">
            <div className="mc-info-icon" style={{ color: 'var(--green)', background: 'var(--green-soft)', borderColor: 'var(--green-border)' }}>
              <Clock3 size={16} />
            </div>
            <div>
              <div className="mc-info-label">Uptime</div>
              <div className="mc-info-value tabular">{fmtUptime(overview?.uptime ?? null)}</div>
            </div>
          </SpotlightCard>
        </motion.div>
      </motion.div>

      {/* telemetry */}
      <div className="mc-section-head">
        <div><p>Container telemetry</p><h2>Resource usage</h2></div>
        <span>{overview?.cpuCores ?? 2} vCPU · {overview ? fmtGiB(overview.memLimit) : '6 GB'} RAM</span>
      </div>

      <motion.div className="mc-telemetry-grid" variants={stagger(0, 0.09)} initial="hidden" animate="show">
        <motion.div variants={cardIn}>
          <TelemetryCard title="CPU" color="orange" icon={<Cpu size={15} />}
            value={overview ? `${overview.cpuPercent.toFixed(1)}%` : '—'}
            numeric={overview?.cpuPercent}
            detail={`of ${overview?.cpuCores ?? 2} vCPU allocated`}
            data={telemetry} dataKey="cpu" tooltip={tooltipContent} skeleton={refreshing && !overview}
          />
        </motion.div>
        <motion.div variants={cardIn}>
          <TelemetryCard title="Memory" color="green" icon={<MemoryStick size={15} />}
            value={overview ? `${fmtGiB(overview.memUsed)} / ${fmtGiB(overview.memLimit)}` : '—'}
            detail={overview ? `${overview.memPercent.toFixed(1)}% of allocation` : '6 GB total'}
            data={telemetry} dataKey="memory" tooltip={tooltipContent} skeleton={refreshing && !overview}
          />
        </motion.div>
      </motion.div>

      {/* players */}
      <motion.div className="mc-player-section" variants={riseIn} initial="hidden" animate="show">
        <div><p>Player activity</p><h2>Currently in the world</h2></div>
        {isOnline && overview?.playerList?.length
          ? (
            <div className="mc-players">
              {overview.playerList.map((p, i) => (
                <motion.span key={p} initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }} transition={{ delay: i * 0.05, ...spring.press }}>
                  {p}
                </motion.span>
              ))}
            </div>
          )
          : <p className="mc-empty-players">No players connected right now.</p>}
      </motion.div>
    </motion.section>
  );
}

/* ── Telemetry card ─────────────────────────────────────────── */
function TelemetryCard({ title, value, numeric, detail, icon, color, data, dataKey, tooltip, skeleton }: {
  title: string; value: string; numeric?: number; detail: string; icon: ReactNode;
  color: 'orange' | 'green'; data: Pt[]; dataKey: 'cpu' | 'memory'; tooltip: any; skeleton: boolean;
}) {
  const stroke = color === 'orange' ? '#f47c48' : '#34d399';
  const glow   = color === 'orange' ? 'rgba(244,124,72,.15)' : 'rgba(52,211,153,.15)';
  return (
    <SpotlightCard className={`mc-telemetry-card ${color}`} glow={glow}>
      <header>
        <span className="mc-telemetry-icon">{icon}</span>
        <div>
          <p>{title} usage</p>
          <strong className="tabular">
            {numeric !== undefined ? <Ticker value={numeric} decimals={1} suffix="%" /> : value}
          </strong>
          <small>{detail}</small>
        </div>
      </header>
      <div className="mc-chart">
        {data.length && !skeleton ? (
          <ResponsiveContainer width="100%" height={180}>
            <AreaChart data={data} margin={{ top: 10, right: 4, bottom: 0, left: -28 }}>
              <defs>
                <linearGradient id={`g-${dataKey}`} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%"   stopColor={stroke} stopOpacity={0.28} />
                  <stop offset="100%" stopColor={stroke} stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="time" hide />
              <YAxis domain={[0, 100]} ticks={[0, 25, 50, 75, 100]}
                tick={{ fontSize: 9, fill: '#44435a' }} axisLine={false} tickLine={false} width={28} />
              <Tooltip cursor={{ stroke: 'rgba(255,255,255,.06)', strokeWidth: 1 }} content={tooltip} />
              <Area type="monotone" dataKey={dataKey} name={title}
                stroke={stroke} strokeWidth={1.5} fill={`url(#g-${dataKey})`} dot={false}
                activeDot={{ r: 4, fill: stroke, stroke: '#0c0c14', strokeWidth: 2 }}
                isAnimationActive={data.length > 1}
              />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <div className="mc-chart-skeleton" aria-label="Loading telemetry"><i /><i /><i /></div>
        )}
      </div>
    </SpotlightCard>
  );
}


/* ════════════════════════════════════════════════════════════════
   CONSOLE TAB
   ════════════════════════════════════════════════════════════════ */
function ConsoleTab({ logs, logsEnd, wsConnected, sendCmd }: {
  logs: { time: string; text: string }[];
  logsEnd: React.RefObject<HTMLDivElement | null>;
  wsConnected: boolean;
  sendCmd: (cmd: string) => void;
}) {
  return (
    <motion.section key="con" className="mc-console-page"
      variants={pageIn} initial="hidden" animate="show" exit="exit">
      <div className="mc-page-heading">
        <div><span>Server output</span><h1>Live console</h1></div>
        <div className={`mc-status ${wsConnected ? 'online' : 'starting'}`}>
          <LiveDot state={wsConnected ? 'online' : 'starting'} />
          {wsConnected ? 'Connected' : 'Reconnecting…'}
        </div>
      </div>
      <div className="mc-terminal">
        <div className="mc-terminal-bar">
          <div className="tl"><i /><i /><i /></div>
          <span className="tb-title">minecraft-server — bash</span>
          <span className={`tb-status${!wsConnected ? ' waiting' : ''}`}>
            {wsConnected ? '● STREAMING' : '○ WAITING'}
          </span>
        </div>
        <div className="mc-terminal-output">
          {logs.length
            ? logs.map((log, i) => (
              <motion.p key={`${log.time}-${i}`}
                initial={{ opacity: 0, x: -8 }} animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.18 }}>
                <time>{log.time}</time><span>{log.text}</span>
              </motion.p>
            ))
            : (
              <div className="mc-terminal-empty">
                {wsConnected ? 'Waiting for output…' : 'Opening stream…'}
                <span className="mc-caret" />
              </div>
            )}
          <div ref={logsEnd} />
        </div>
        <form className="mc-terminal-input"
          onSubmit={e => { e.preventDefault(); const el = e.currentTarget.elements.namedItem('cmd') as HTMLInputElement; sendCmd(el.value); el.value = ''; }}>
          <span>›</span>
          <input name="cmd" autoComplete="off" spellCheck={false} placeholder="Run a Minecraft command…" />
        </form>
      </div>
    </motion.section>
  );
}

/* ════════════════════════════════════════════════════════════════
   PLAYERS TAB
   ════════════════════════════════════════════════════════════════ */
type PlayerListType = 'whitelist' | 'ops' | 'banned-players';

function PlayersTab() {
  const [activeList, setActiveList] = useState<PlayerListType>('whitelist');
  const [players,    setPlayers]    = useState<Record<PlayerListType, PlayerEntry[]>>({
    whitelist: [], ops: [], 'banned-players': [],
  });
  const [loading, setLoading]   = useState(true);
  const [addName, setAddName]   = useState('');
  const [saving,  setSaving]    = useState(false);

  const load = useCallback(async (type: PlayerListType) => {
    setLoading(true);
    try {
      const r = await fetch(`/api/minecraft/players/${type}`);
      const d = await r.json();
      setPlayers(prev => ({ ...prev, [type]: Array.isArray(d) ? d : [] }));
    } catch { /* keep empty */ }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { void load(activeList); }, [activeList, load]);

  const save = async (type: PlayerListType, list: PlayerEntry[]) => {
    setSaving(true);
    try {
      await fetch(`/api/minecraft/players/${type}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(list),
      });
      setPlayers(prev => ({ ...prev, [type]: list }));
    } finally { setSaving(false); }
  };

  const addPlayer = () => {
    const name = addName.trim();
    if (!name) return;
    const list = players[activeList];
    if (list.find(p => p.name.toLowerCase() === name.toLowerCase())) return;
    const updated = [...list, { uuid: '', name }];
    setAddName('');
    void save(activeList, updated);
  };

  const removePlayer = (name: string) => {
    const updated = players[activeList].filter(p => p.name !== name);
    void save(activeList, updated);
  };

  const LIST_LABELS: Record<PlayerListType, string> = {
    whitelist: 'Whitelist', ops: 'Operators', 'banned-players': 'Banned Players',
  };

  return (
    <motion.section variants={pageIn} initial="hidden" animate="show" exit="exit">
      <div className="mc-page-heading">
        <div><span>Access control</span><h1>Player management</h1></div>
      </div>

      {/* list selector */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {(['whitelist', 'ops', 'banned-players'] as PlayerListType[]).map(type => (
          <motion.button key={type}
            className={activeList === type ? 'btn btn-primary' : 'btn'}
            onClick={() => setActiveList(type)}
            whileHover={{ y: -1 }} whileTap={{ scale: 0.97 }} transition={spring.press}
            style={{ fontSize: 12 }}>
            {type === 'whitelist' && <Shield size={12} />}
            {type === 'ops' && <Users size={12} />}
            {type === 'banned-players' && <MinusCircle size={12} />}
            {LIST_LABELS[type]}
          </motion.button>
        ))}
      </div>

      <motion.div className="mc-players-page" variants={stagger(0, 0.06)} initial="hidden" animate="show">
        <motion.div className="mc-players-panel" variants={cardIn}>
          <div className="mc-players-panel-head">
            <h3>{LIST_LABELS[activeList]}</h3>
            <span>{players[activeList].length} {players[activeList].length === 1 ? 'player' : 'players'}</span>
          </div>
          <div className="mc-players-add">
            <input
              value={addName}
              onChange={e => setAddName(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && addPlayer()}
              placeholder={`Add player to ${LIST_LABELS[activeList].toLowerCase()}…`}
            />
            <motion.button className="btn btn-primary" onClick={addPlayer} disabled={saving || !addName.trim()}
              whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}
              style={{ gap: 6 }}>
              <Plus size={13} /> Add
            </motion.button>
          </div>
          <div className="mc-player-list">
            {loading
              ? <div className="mc-players-empty">Loading…</div>
              : players[activeList].length === 0
                ? <div className="mc-players-empty">No players in this list.</div>
                : players[activeList].map(p => (
                  <div key={p.name} className="mc-player-row">
                    <div className="mc-player-avatar">{p.name.charAt(0).toUpperCase()}</div>
                    <div>
                      <div className="mc-player-name">{p.name}</div>
                      {p.uuid && <div className="mc-player-uuid">{p.uuid}</div>}
                    </div>
                    <button className="mc-player-remove" onClick={() => removePlayer(p.name)} aria-label={`Remove ${p.name}`}>
                      <Trash2 size={13} />
                    </button>
                  </div>
                ))}
          </div>
        </motion.div>
      </motion.div>
    </motion.section>
  );
}


/* ════════════════════════════════════════════════════════════════
   FILES TAB
   ════════════════════════════════════════════════════════════════ */
function FilesTab() {
  const [path,      setPath]      = useState('');
  const [entries,   setEntries]   = useState<FileEntry[]>([]);
  const [selected,  setSelected]  = useState<string | null>(null);
  const [content,   setContent]   = useState('');
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'saved' | 'error'>('idle');
  const [loading,   setLoading]   = useState(true);
  const uploadRef = useRef<HTMLInputElement>(null);

  const listDir = useCallback(async (p: string) => {
    setLoading(true); setSelected(null); setContent('');
    try {
      const r = await fetch(`/api/files/list?path=${encodeURIComponent(p)}`);
      setEntries(await r.json());
      setPath(p);
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { void listDir(''); }, [listDir]);

  const openFile = async (name: string) => {
    const filePath = path ? `${path}/${name}` : name;
    setSelected(filePath);
    try {
      const r = await fetch(`/api/files/read?path=${encodeURIComponent(filePath)}`);
      setContent(await r.text());
      setSaveState('idle');
    } catch { setContent('Could not read file.'); }
  };

  const saveFile = async () => {
    if (!selected) return;
    setSaveState('saving');
    try {
      await fetch('/api/files/save', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path: selected, content }),
      });
      setSaveState('saved');
      setTimeout(() => setSaveState('idle'), 2000);
    } catch { setSaveState('error'); }
  };

  const uploadFile = async (file: File) => {
    const fd = new FormData(); fd.append('file', file); fd.append('path', path);
    await fetch('/api/files/upload', { method: 'POST', body: fd });
    void listDir(path);
  };

  const breadcrumbs = path ? path.split('/') : [];

  return (
    <motion.section variants={pageIn} initial="hidden" animate="show" exit="exit">
      <div className="mc-page-heading">
        <div><span>Data directory</span><h1>File manager</h1></div>
        <div style={{ display: 'flex', gap: 8 }}>
          <input ref={uploadRef} type="file" style={{ display: 'none' }}
            onChange={e => e.target.files?.[0] && uploadFile(e.target.files[0])} />
          <motion.button className="btn" onClick={() => uploadRef.current?.click()}
            whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
            <Upload size={13} /> Upload
          </motion.button>
        </div>
      </div>

      <div className="mc-files-layout">
        {/* Browser panel */}
        <div className="mc-file-browser">
          <div className="mc-file-browser-head">
            <Folder size={13} />
            <div className="mc-breadcrumb">
              <button onClick={() => listDir('')}>/data</button>
              {breadcrumbs.map((seg, i) => (
                <span key={i}>
                  <span style={{ color: 'var(--border-bright)', margin: '0 3px' }}>/</span>
                  <button onClick={() => listDir(breadcrumbs.slice(0, i + 1).join('/'))}>{seg}</button>
                </span>
              ))}
            </div>
          </div>
          <div className="mc-file-list">
            {path && (
              <div className="mc-file-entry" onClick={() => listDir(breadcrumbs.slice(0, -1).join('/'))}>
                <Folder size={13} /><span style={{ color: 'var(--text-dim)' }}>..</span>
              </div>
            )}
            {loading
              ? <div style={{ padding: '20px', color: 'var(--text-dim)', fontSize: 12 }}>Loading…</div>
              : entries.map(f => (
                <div key={f.name}
                  className={`mc-file-entry${selected === (path ? `${path}/${f.name}` : f.name) ? ' active' : ''}`}
                  onClick={() => f.isDir ? listDir(path ? `${path}/${f.name}` : f.name) : openFile(f.name)}>
                  {f.isDir ? <Folder size={13} /> : <FileText size={13} />}
                  <span>{f.name}</span>
                  {!f.isDir && <small>{fmtSize(f.size)}</small>}
                </div>
              ))}
          </div>
        </div>

        {/* Editor panel */}
        <div className="mc-file-editor">
          {selected ? (
            <>
              <div className="mc-file-editor-head">
                <span className="mc-file-editor-title"><File size={12} style={{ display: 'inline', marginRight: 6 }} />{selected}</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  {saveState !== 'idle' && (
                    <span className={`mc-save-status ${saveState}`}>
                      {saveState === 'saving' && <><RefreshCw size={11} /> Saving…</>}
                      {saveState === 'saved'  && <><Check size={11} /> Saved</>}
                      {saveState === 'error'  && 'Save failed'}
                    </span>
                  )}
                  <motion.button className="btn btn-primary" onClick={saveFile} disabled={saveState === 'saving'}
                    whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}
                    style={{ fontSize: 12, gap: 6 }}>
                    <Save size={12} /> Save
                  </motion.button>
                </div>
              </div>
              <textarea value={content} onChange={e => setContent(e.target.value)}
                spellCheck={false} style={{ flex: 1 }} />
            </>
          ) : (
            <div className="mc-file-empty">
              <FileText size={28} style={{ opacity: .3 }} />
              <span>Select a file to edit</span>
            </div>
          )}
        </div>
      </div>
    </motion.section>
  );
}

/* ════════════════════════════════════════════════════════════════
   BACKUPS TAB
   ════════════════════════════════════════════════════════════════ */
function BackupsTab() {
  const [backups,  setBackups]  = useState<BackupEntry[]>([]);
  const [loading,  setLoading]  = useState(true);
  const [deleting, setDeleting] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try { const r = await fetch('/api/backups'); setBackups(await r.json()); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const deleteBackup = async (name: string) => {
    setDeleting(name);
    try {
      await fetch(`/api/backups/${encodeURIComponent(name)}`, { method: 'DELETE' });
      setBackups(prev => prev.filter(b => b.name !== name));
    } finally { setDeleting(null); }
  };

  return (
    <motion.section variants={pageIn} initial="hidden" animate="show" exit="exit">
      <div className="mc-page-heading">
        <div><span>Google Drive</span><h1>Backup manager</h1></div>
        <motion.button className="btn" onClick={load} disabled={loading}
          whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}>
          <RefreshCw size={13} className={loading ? 'spin' : ''} /> Refresh
        </motion.button>
      </div>

      <div className="mc-backup-info">
        <Database size={15} />
        <span>Backups are created automatically every 5 minutes and stored on Google Drive. A maximum of 3 rolling backups are kept.</span>
      </div>

      <div style={{ marginTop: 20 }}>
        {loading ? (
          <div className="mc-backups-empty"><RefreshCw size={20} style={{ opacity: .4 }} /><span>Loading backups…</span></div>
        ) : backups.length === 0 ? (
          <div className="mc-backups-empty">
            <Database size={28} style={{ opacity: .3 }} />
            <span>No backups found on Google Drive.</span>
            <small style={{ color: 'var(--text-dim)', fontSize: 11 }}>Backups are created automatically every 5 minutes.</small>
          </div>
        ) : (
          <motion.div className="mc-backup-list" variants={stagger(0, 0.06)} initial="hidden" animate="show">
            {backups.map(b => (
              <motion.div key={b.name} className="mc-backup-row" variants={cardIn}>
                <div className="mc-backup-icon"><Database size={16} /></div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="mc-backup-name">{b.name}</div>
                  <div className="mc-backup-date">{new Date(b.modified).toLocaleString()}</div>
                </div>
                <span className="mc-backup-size">{fmtSize(b.size)}</span>
                <motion.button className="mc-backup-delete"
                  onClick={() => deleteBackup(b.name)}
                  disabled={deleting === b.name}
                  whileTap={{ scale: 0.9 }} transition={spring.press}
                  aria-label={`Delete ${b.name}`}>
                  {deleting === b.name ? <RefreshCw size={13} /> : <Trash2 size={13} />}
                </motion.button>
              </motion.div>
            ))}
          </motion.div>
        )}
      </div>
    </motion.section>
  );
}


/* ════════════════════════════════════════════════════════════════
   OPTIONS TAB — server.properties editor
   ════════════════════════════════════════════════════════════════ */
function OptionsTab() {
  const [raw,       setRaw]       = useState('');
  const [props,     setProps]     = useState<{ key: string; value: string }[]>([]);
  const [viewMode,  setViewMode]  = useState<'visual' | 'raw'>('visual');
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'saved' | 'error'>('idle');
  const [loading,   setLoading]   = useState(true);

  useEffect(() => {
    fetch('/api/minecraft/properties')
      .then(r => r.json())
      .then(d => {
        const content: string = d.content || '';
        setRaw(content);
        setProps(parseProps(content));
      })
      .finally(() => setLoading(false));
  }, []);

  function parseProps(content: string) {
    return content.split('\n')
      .filter(line => line.trim() && !line.startsWith('#'))
      .map(line => {
        const eq = line.indexOf('=');
        return eq >= 0 ? { key: line.slice(0, eq).trim(), value: line.slice(eq + 1).trim() } : null;
      })
      .filter(Boolean) as { key: string; value: string }[];
  }

  function propsToRaw(list: { key: string; value: string }[]) {
    return list.map(p => `${p.key}=${p.value}`).join('\n');
  }

  const setPropValue = (key: string, value: string) => {
    setProps(prev => prev.map(p => p.key === key ? { ...p, value } : p));
  };

  const save = async () => {
    setSaveState('saving');
    const content = viewMode === 'visual' ? propsToRaw(props) : raw;
    try {
      await fetch('/api/minecraft/properties', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content }),
      });
      setSaveState('saved');
      setTimeout(() => setSaveState('idle'), 2500);
    } catch { setSaveState('error'); }
  };

  /* important props shown first in visual mode */
  const PRIORITY = ['server-name', 'motd', 'max-players', 'gamemode', 'difficulty',
    'pvp', 'online-mode', 'white-list', 'enforce-whitelist', 'view-distance',
    'spawn-protection', 'level-name', 'level-seed', 'server-port'];
  const sorted = [...props].sort((a, b) => {
    const ai = PRIORITY.indexOf(a.key); const bi = PRIORITY.indexOf(b.key);
    if (ai >= 0 && bi >= 0) return ai - bi;
    if (ai >= 0) return -1; if (bi >= 0) return 1;
    return a.key.localeCompare(b.key);
  });

  return (
    <motion.section variants={pageIn} initial="hidden" animate="show" exit="exit">
      <div className="mc-page-heading">
        <div><span>Server configuration</span><h1>server.properties</h1></div>
        <div style={{ display: 'flex', gap: 8 }}>
          {(['visual', 'raw'] as const).map(m => (
            <motion.button key={m} className={viewMode === m ? 'btn btn-primary' : 'btn'}
              onClick={() => {
                if (m === 'raw' && viewMode === 'visual') setRaw(propsToRaw(props));
                if (m === 'visual' && viewMode === 'raw') setProps(parseProps(raw));
                setViewMode(m);
              }}
              whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}
              style={{ fontSize: 12, textTransform: 'capitalize' }}>
              {m}
            </motion.button>
          ))}
        </div>
      </div>

      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-dim)', fontSize: 12 }}>
          Loading server.properties…
        </div>
      ) : (
        <div className="mc-options-editor">
          {viewMode === 'visual' ? (
            <>
              <div className="mc-options-head">
                <h3>Server properties</h3>
                <span style={{ color: 'var(--text-dim)', fontSize: 11 }}>{props.length} settings</span>
              </div>
              <div className="mc-options-properties">
                {sorted.map(p => (
                  <div key={p.key} className="mc-prop-row">
                    <span className="mc-prop-key">{p.key}</span>
                    <input className="mc-prop-val" value={p.value}
                      onChange={e => setPropValue(p.key, e.target.value)} />
                  </div>
                ))}
              </div>
            </>
          ) : (
            <textarea className="mc-options-raw" value={raw}
              onChange={e => setRaw(e.target.value)}
              style={{ minHeight: 500, padding: 20, resize: 'none', border: 0, outline: 0,
                background: '#0c0c14', color: '#c4c2d4',
                font: '12px/1.8 "JetBrains Mono", monospace', width: '100%' }}
              spellCheck={false}
            />
          )}
          <div className="mc-save-bar">
            <span>Changes take effect after a server restart.</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {saveState !== 'idle' && (
                <span className={`mc-save-status ${saveState}`}>
                  {saveState === 'saving' && <><RefreshCw size={11} /> Saving…</>}
                  {saveState === 'saved'  && <><Check size={11} /> Saved successfully</>}
                  {saveState === 'error'  && 'Failed to save'}
                </span>
              )}
              <motion.button className="btn btn-primary" onClick={save} disabled={saveState === 'saving'}
                whileHover={{ y: -1 }} whileTap={{ scale: 0.96 }} transition={spring.press}
                style={{ gap: 6 }}>
                <Save size={13} /> Save changes
              </motion.button>
            </div>
          </div>
        </div>
      )}
    </motion.section>
  );
}
