import type { Transition, Variants } from 'framer-motion';

/* ─── Easing curves ──────────────────────────────────────────── */
export const ease = {
  out:        [0.22, 1,    0.36, 1]    as [number,number,number,number],
  inOut:      [0.65, 0,    0.35, 1]    as [number,number,number,number],
  overshoot:  [0.34, 1.56, 0.64, 1]   as [number,number,number,number],
  snappy:     [0.18, 0.9,  0.28, 1.05] as [number,number,number,number],
};

/* ─── Spring presets ─────────────────────────────────────────── */
export const spring = {
  /** Ultra-snappy: buttons, chips, toggles — immediate tactile response */
  press:  { type: 'spring', stiffness: 700, damping: 36, mass: 0.5  } satisfies Transition,
  /** Card lift and settle — perceptibly physical */
  lift:   { type: 'spring', stiffness: 380, damping: 30, mass: 0.8  } satisfies Transition,
  /** Smooth slide — panels, drawers, tab pills */
  glide:  { type: 'spring', stiffness: 260, damping: 28, mass: 0.9  } satisfies Transition,
  /** Slow ambient drift — background layers, hero elements */
  drift:  { type: 'spring', stiffness: 100, damping: 22, mass: 1.2  } satisfies Transition,
  /** Gentle modal / overlay entrance */
  modal:  { type: 'spring', stiffness: 240, damping: 26, mass: 1.1  } satisfies Transition,
};

/* ─── Variant factories ──────────────────────────────────────── */

/** Stagger container */
export const stagger = (delayChildren = 0.04, staggerChildren = 0.055): Variants => ({
  hidden: {},
  show:   { transition: { delayChildren, staggerChildren } },
  exit:   {},
});

/** Rise + fade + blur — primary entrance for headings / copy */
export const riseIn: Variants = {
  hidden: { opacity: 0, y: 18, filter: 'blur(8px)' },
  show:   { opacity: 1, y: 0,  filter: 'blur(0px)',
            transition: { duration: 0.6, ease: ease.out } },
  exit:   { opacity: 0, y: -8, filter: 'blur(4px)',
            transition: { duration: 0.25, ease: ease.inOut } },
};

/** Pure fade */
export const fadeIn: Variants = {
  hidden: { opacity: 0 },
  show:   { opacity: 1, transition: { duration: 0.5, ease: ease.out } },
  exit:   { opacity: 0, transition: { duration: 0.2 } },
};

/** Card pop-in — scale + rise + fade */
export const cardIn: Variants = {
  hidden: { opacity: 0, y: 24, scale: 0.96, filter: 'blur(4px)' },
  show:   { opacity: 1, y: 0,  scale: 1,    filter: 'blur(0px)',
            transition: { duration: 0.55, ease: ease.out } },
  exit:   { opacity: 0, y: -10, scale: 0.98,
            transition: { duration: 0.2,  ease: ease.inOut } },
};

/** Route-level page transition */
export const pageIn: Variants = {
  hidden: { opacity: 0, y: 16, filter: 'blur(6px)' },
  show:   { opacity: 1, y: 0,  filter: 'blur(0px)',
            transition: { duration: 0.45, ease: ease.out } },
  exit:   { opacity: 0, y: -12, filter: 'blur(4px)',
            transition: { duration: 0.22, ease: ease.inOut } },
};

/** Slide in from the left (sidebar, drawer) */
export const slideInLeft: Variants = {
  hidden: { opacity: 0, x: -32, filter: 'blur(6px)' },
  show:   { opacity: 1, x: 0,   filter: 'blur(0px)',
            transition: { duration: 0.5, ease: ease.out } },
  exit:   { opacity: 0, x: -20,
            transition: { duration: 0.22, ease: ease.inOut } },
};

/** Scale pop — for badges, pills, status indicators */
export const popIn: Variants = {
  hidden: { opacity: 0, scale: 0.7 },
  show:   { opacity: 1, scale: 1,
            transition: { type: 'spring', stiffness: 500, damping: 26, mass: 0.6 } },
  exit:   { opacity: 0, scale: 0.7,
            transition: { duration: 0.15 } },
};
