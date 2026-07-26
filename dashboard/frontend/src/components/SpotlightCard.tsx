import {
  motion,
  useMotionTemplate,
  useMotionValue,
  useReducedMotion,
  useSpring,
} from 'framer-motion';
import { useRef, type CSSProperties, type KeyboardEvent, type ReactNode } from 'react';
import { spring } from '../lib/motion';

interface Props {
  children: ReactNode;
  className?: string;
  interactive?: boolean;
  /** Accent colour for the cursor spotlight radial. */
  glow?: string;
  onClick?: () => void;
  onMouseEnter?: () => void;
  onFocus?: () => void;
  style?: CSSProperties;
}

/**
 * Surface that tracks the pointer:
 * - A soft radial spotlight follows the cursor.
 * - Cards tilts ±5 ° toward the pointer (clamped, disabled under reduced motion).
 * - Border brightens on hover via a travelling sheen.
 */
export default function SpotlightCard({
  children,
  className = '',
  interactive = false,
  glow = 'rgba(139,92,246,.18)',
  onClick,
  onMouseEnter,
  onFocus,
  style,
}: Props) {
  const ref   = useRef<HTMLDivElement>(null);
  const still = useReducedMotion();

  /* pointer-relative coordinates */
  const mouseX = useMotionValue(-500);
  const mouseY = useMotionValue(-500);

  /* spring-smoothed tilt values */
  const rotX = useSpring(useMotionValue(0), spring.glide);
  const rotY = useSpring(useMotionValue(0), spring.glide);

  /* spotlight radial */
  const spotlight = useMotionTemplate`
    radial-gradient(360px circle at ${mouseX}px ${mouseY}px, ${glow}, transparent 75%)
  `;

  const track = (e: React.MouseEvent<HTMLDivElement>) => {
    if (still) return;
    const b = ref.current?.getBoundingClientRect();
    if (!b) return;
    const x = e.clientX - b.left;
    const y = e.clientY - b.top;
    mouseX.set(x);
    mouseY.set(y);
    if (!interactive) return;
    rotY.set(((x / b.width)  - 0.5) * 10);
    rotX.set(((y / b.height) - 0.5) * -10);
  };

  const reset = () => {
    mouseX.set(-500);
    mouseY.set(-500);
    rotX.set(0);
    rotY.set(0);
  };

  const keyActivate = (e: KeyboardEvent<HTMLDivElement>) => {
    if (onClick && (e.key === 'Enter' || e.key === ' ')) {
      e.preventDefault();
      onClick();
    }
  };

  return (
    <motion.div
      ref={ref}
      className={`spotlight-card ${interactive ? 'is-interactive' : ''} ${className}`}
      style={{ ...style, rotateX: rotX, rotateY: rotY, transformPerspective: 1200 }}
      onMouseMove={track}
      onMouseLeave={reset}
      onMouseEnter={onMouseEnter}
      onFocus={onFocus}
      onClick={onClick}
      onKeyDown={keyActivate}
      tabIndex={onClick ? 0 : undefined}
      role={onClick ? 'button' : undefined}
      whileHover={interactive && !still ? { y: -7, scale: 1.008 } : undefined}
      whileTap={interactive   && !still ? { scale: 0.984 } : undefined}
      transition={spring.lift}
    >
      {/* cursor spotlight */}
      <motion.span
        className="spotlight-glow"
        style={{ background: spotlight }}
        aria-hidden="true"
      />

      {/* top-edge sheen line */}
      <span className="spotlight-edge" aria-hidden="true" />

      <div className="spotlight-content">{children}</div>
    </motion.div>
  );
}
