// Marchio SBonus in stile "Sole": la S seguita da "Bonus" in una pillola blu notte.
export function Logo({ className = "" }: { className?: string }) {
  return (
    <span className={`inline-flex items-center text-[1.55rem] font-black leading-none tracking-tight text-ink ${className}`}>
      S
      <span className="ml-0.5 rounded-xl bg-ink px-2.5 py-1 text-sun">Bonus</span>
    </span>
  );
}
