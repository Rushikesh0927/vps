export interface MinecraftOverview {
  status: 'online' | 'offline' | 'starting';
  players: number;
  maxPlayers: number;
  playerList: string[];
  uptime: string | null;
  serverIp: string;
  bedrockIp?: string | null;
  running: boolean;
  cpuPercent: number;
  cpuCores: number;
  memUsed: number;
  memLimit: number;
  memPercent: number;
  rxBytes: number;
  txBytes: number;
}

interface StoredOverview { savedAt: number; data: MinecraftOverview; }

const STORAGE_KEY = 'vps-minecraft-overview';
const MAX_STALE_MS = 45_000;
let memoryCache: StoredOverview | null = null;
let request: Promise<MinecraftOverview> | null = null;

function getStored(): StoredOverview | null {
  if (memoryCache) return memoryCache;
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as StoredOverview;
    if (!parsed?.data || Date.now() - parsed.savedAt > MAX_STALE_MS) return null;
    memoryCache = parsed;
    return parsed;
  } catch { return null; }
}

function save(data: MinecraftOverview) {
  memoryCache = { savedAt: Date.now(), data };
  try { sessionStorage.setItem(STORAGE_KEY, JSON.stringify(memoryCache)); } catch {}
  return data;
}

export function getCachedMinecraftOverview() { return getStored()?.data ?? null; }

export async function loadMinecraftOverview() {
  if (!request) {
    request = fetch('/api/minecraft/overview', { cache: 'no-store' })
      .then(async response => {
        if (!response.ok) throw new Error('Unable to load Minecraft overview');
        return save(await response.json() as MinecraftOverview);
      })
      .finally(() => { request = null; });
  }
  return request;
}

export function preloadMinecraftOverview() {
  void loadMinecraftOverview().catch(() => {});
}
