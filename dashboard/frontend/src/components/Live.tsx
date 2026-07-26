import { motion, useReducedMotion } from 'framer-motion';
import { ease } from '../lib/motion';

/**
 * A meter that fills with a spring and carries a travelling sheen while it moves,
 * plus a bright head so the current value reads as a live edge rather than a bar end.
 */
export function Meter({ percent, tone = 'accent' }: { percent: number; tone?: 'accent' | 'good' | 'warn' | 'bad' }) {
  const clamped = Math.min(100, Math.max(0, percent));
  const still = useReducedMotion();
  return (
    <div className="meter" data-tone={tone} role="progressbar" aria-valuenow={Math.round(clamped)} aria-valuemin={0} aria-valuemax={100}>
      <motion.i
        initial={{ width: 0 }}
        animate={{ width: `${clamped}%` }}
        transition={still ? { duration: 0 } : { duration: 0.9, ease: ease.out }}
      >
        <span className="meter-sheen" />
        <span className="meter-head" />
      </motion.i>
    </div>
  );
}

/** A status dot that emits a slow expanding ring while the service is healthy. */
export function LiveDot({ state }: { state: 'online' | 'offline' | 'starting' }) {
  return (
    <span className={`live-dot live-dot-${state}`}>
      {state === 'online' && <span className="live-dot-ring" />}
      {state === 'starting' && <span className="live-dot-ring live-dot-ring-fast" />}
    </span>
  );
}
