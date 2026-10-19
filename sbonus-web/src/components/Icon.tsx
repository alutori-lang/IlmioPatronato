import type { IconName } from "@/lib/categories";

// Set di icone a tratto, coerenti (24×24, stroke 1.8). Nessuna dipendenza esterna.
const PATHS: Record<IconName | "menu" | "close" | "arrow" | "external" | "check" | "info" | "alert" | "calendar", string> = {
  family: "M8 7a3 3 0 1 0 0-.01M17 8.5a2.5 2.5 0 1 0 0-.01M3 20c0-3 2.2-5.5 5-5.5s5 2.5 5 5.5M13.5 20c.2-2.4 1.6-4.3 3.5-4.3s3.5 2 3.5 4.3",
  work: "M4 8h16v11H4zM9 8V5.5h6V8M4 13h16",
  home: "M4 11 12 4l8 7M6 9.5V20h12V9.5M10 20v-5h4v5",
  elderly: "M12 6.5a2 2 0 1 0 0-.01M12 9v5l-3 6M12 14l3 6M9 11l6 1M17 12v8",
  inps: "M4 20h16M5 10h14M12 4l8 4H4zM7 10v8M12 10v8M17 10v8",
  tax: "M7 3h10v18l-2-1.5L13 21l-2-1.5L9 21l-2-1.5zM9.5 8h5M9.5 12h5M9.5 16h3",
  isee: "M4 20V10M10 20V4M16 20v-7M22 20H2",
  school: "M2 9l10-5 10 5-10 5zM6 11v5c0 1.5 2.7 3 6 3s6-1.5 6-3v-5",
  health: "M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10zM12 9v5M9.5 11.5h5",
  support: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM8 13.5c1 1.4 2.4 2 4 2s3-.6 4-2M9 9.5h.01M15 9.5h.01",
  map: "M9 4 3 6v14l6-2 6 2 6-2V4l-6 2zM9 4v14M15 6v14",
  calc: "M6 3h12v18H6zM9 7h6M9 11h.01M12 11h.01M15 11h.01M9 14h.01M12 14h.01M15 14v3M9 17h.01M12 17h.01",
  search: "M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4",
  book: "M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2zM4 5v16M8 7h7",
  phone: "M8 2h8a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1zM11 18h2",
  euro: "M17 6.5A6.5 6.5 0 1 0 17 17.5M4 10h9M4 14h9",
  menu: "M4 7h16M4 12h16M4 17h16",
  close: "M6 6l12 12M18 6 6 18",
  arrow: "M5 12h14M13 6l6 6-6 6",
  external: "M14 4h6v6M20 4l-9 9M18 14v6H4V6h6",
  check: "M5 12.5l4.5 4.5L19 7",
  info: "M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v6M12 7.5h.01",
  alert: "M12 3 2 20h20zM12 10v4M12 17h.01",
  calendar: "M4 6h16v14H4zM4 10h16M8 3v4M16 3v4",
};

export type AnyIcon = keyof typeof PATHS;

export function Icon({ name, className = "h-5 w-5", label }: { name: AnyIcon; className?: string; label?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden={label ? undefined : true}
      role={label ? "img" : undefined}
      aria-label={label}
    >
      <path d={PATHS[name]} />
    </svg>
  );
}
