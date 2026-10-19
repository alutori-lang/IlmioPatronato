/** Onda gialla che chiude le testate: il segno distintivo dello stile "Sole". */
export function Wave({ className = "" }: { className?: string }) {
  return (
    <svg className={`block h-10 w-full sm:h-14 ${className}`} viewBox="0 0 1440 60" preserveAspectRatio="none" aria-hidden="true">
      <path d="M0 0h1440v20c-240 40-480 40-720 20S240 0 0 30z" fill="var(--sun)" />
    </svg>
  );
}
