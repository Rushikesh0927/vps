import { useReducedMotion } from 'framer-motion';

interface Props {
  variant?: 'default' | 'auth';
}

/**
 * Fixed full-viewport background layer.
 * z-index: 0 — all page shells must be z-index ≥ 1.
 */
export default function Ambient({ variant = 'default' }: Props) {
  const still = useReducedMotion();
  const cls   = [
    'ambient',
    variant === 'auth' ? 'ambient-auth' : '',
    still              ? 'ambient-still' : '',
  ].filter(Boolean).join(' ');

  return (
    <div className={cls} aria-hidden="true">
      {/* layered mesh gradient base */}
      <div className="ambient-mesh" />

      {/* colour orbs */}
      <div className="ambient-orb ambient-orb-1" />
      <div className="ambient-orb ambient-orb-2" />
      <div className="ambient-orb ambient-orb-3" />
      <div className="ambient-orb ambient-orb-4" />

      {/* fine grid */}
      <div className="ambient-grid" />

      {/* scan beam */}
      <div className="ambient-scan" />

      {/* film grain */}
      <div className="ambient-grain" />

      {/* edge vignette — keeps focus toward centre */}
      <div className="ambient-vignette" />
    </div>
  );
}
