import { useId } from "react";

// Marchio SBonus: una "S" che diventa freccia di crescita dentro un sigillo
// arrotondato. Volutamente lontano dai simboli istituzionali (niente stemmi o tricolore).
export function LogoMark({ className = "h-9 w-9" }: { className?: string }) {
  const gid = `sb-g-${useId().replace(/:/g, "")}`;
  return (
    <svg viewBox="0 0 40 40" className={className} aria-hidden="true">
      <defs>
        <linearGradient id={gid} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#2a62f0" />
          <stop offset="1" stopColor="#1438a3" />
        </linearGradient>
      </defs>
      <rect width="40" height="40" rx="11" fill={`url(#${gid})`} />
      <path
        d="M26.5 13.2c-1.4-1.6-3.6-2.4-6.2-2.4-3.6 0-6.1 1.9-6.1 4.7 0 2.7 2.2 3.8 5.6 4.5l1.6.3c2.4.5 3.6 1.2 3.6 2.6 0 1.6-1.6 2.6-4 2.6-2.3 0-4.2-.9-5.4-2.5"
        fill="none"
        stroke="#fff"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <path d="M25 27.5l4-4.4M29 23.1v3.9M29 23.1h-3.9" stroke="#3ee0a1" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
  );
}

export function Logo({ className = "", chiaro = false }: { className?: string; chiaro?: boolean }) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <LogoMark />
      <span className={`font-display text-[1.35rem] font-extrabold tracking-tight ${chiaro ? "text-white" : "text-ink"}`}>
        S<span className={chiaro ? "text-[#7df3c4]" : "text-brand"}>Bonus</span>
      </span>
    </span>
  );
}
