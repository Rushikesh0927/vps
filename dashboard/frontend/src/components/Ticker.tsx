import { animate, useInView, useMotionValue, useReducedMotion, useTransform, motion } from 'framer-motion';
import { useEffect, useRef } from 'react';

/**
 * Counts to `value` instead of snapping. Re-animates from the previous number on
 * every update, so live telemetry visibly moves rather than blinking.
 */
export default function Ticker({ value, decimals = 0, suffix = '', prefix = '', duration = 0.9 }: { value: number; decimals?: number; suffix?: string; prefix?: string; duration?: number }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: '-40px' });
  const still = useReducedMotion();
  const count = useMotionValue(0);
  const text = useTransform(count, latest => `${prefix}${latest.toFixed(decimals)}${suffix}`);

  useEffect(() => {
    if (!inView) return;
    if (still) { count.set(value); return; }
    const controls = animate(count, value, { duration, ease: [0.22, 1, 0.36, 1] });
    return () => controls.stop();
  }, [value, inView, still, count, duration]);

  return <motion.span ref={ref}>{text}</motion.span>;
}
