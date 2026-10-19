// Marchio SBonus: la S seguita da "Bonus" in una pillola (bianca sulla testata blu).
export function Logo({ className = "", chiaro = false }: { className?: string; chiaro?: boolean }) {
  return (
    <span className={`inline-flex items-center text-[1.55rem] font-black leading-none tracking-tight ${chiaro ? "text-white" : "text-ink"} ${className}`}>
      S
      <span className={`ml-0.5 rounded-xl px-2.5 py-1 ${chiaro ? "bg-white text-blu-1" : "bg-ink text-sun"}`}>Bonus</span>
    </span>
  );
}
