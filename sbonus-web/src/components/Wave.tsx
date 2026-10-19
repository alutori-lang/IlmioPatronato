/** Onda blu che chiude le testate, con lo stesso gradiente della testata. */
export function Wave({ className = "" }: { className?: string }) {
  return (
    <svg className={`block h-10 w-full sm:h-14 ${className}`} viewBox="0 0 1440 60" preserveAspectRatio="none" aria-hidden="true">
      <defs>
        <linearGradient id="onda-blu" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor="#0d47a1" />
          <stop offset="0.55" stopColor="#1565c0" />
          <stop offset="1" stopColor="#1976d2" />
        </linearGradient>
      </defs>
      <path d="M0 0h1440v20c-240 40-480 40-720 20S240 0 0 30z" fill="url(#onda-blu)" />
    </svg>
  );
}
