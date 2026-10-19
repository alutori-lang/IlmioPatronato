"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { NAV } from "@/lib/site";
import { Logo } from "./Logo";
import { Icon } from "./Icon";
import { SearchBox } from "./SearchBox";

export function Header() {
  const pathname = usePathname();
  // Il pannello aperto è legato alla pagina: cambiando pagina si chiude da solo.
  const [aperto, setAperto] = useState<{ path: string; cosa: "menu" | "search" } | null>(null);
  const menu = aperto?.path === pathname && aperto.cosa === "menu";
  const search = aperto?.path === pathname && aperto.cosa === "search";
  const setMenu = (v: boolean | ((m: boolean) => boolean)) => {
    const next = typeof v === "function" ? v(menu) : v;
    setAperto(next ? { path: pathname, cosa: "menu" } : null);
  };
  const setSearch = (v: boolean | ((s: boolean) => boolean)) => {
    const next = typeof v === "function" ? v(search) : v;
    setAperto(next ? { path: pathname, cosa: "search" } : null);
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setAperto(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const isActive = (href: string) => pathname === href || pathname.startsWith(`${href}/`);

  return (
    <header className="bg-blu sticky top-0 z-40">
      <a href="#contenuto" className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-3 focus:rounded-full focus:bg-white focus:px-4 focus:py-2 focus:text-blu-1">
        Vai al contenuto
      </a>
      <div className="mx-auto flex h-[72px] max-w-6xl items-center gap-4 px-4 sm:px-6">
        <Link href="/" aria-label="SBonus, vai alla home" className="shrink-0">
          <Logo chiaro />
        </Link>

        <nav aria-label="Principale" className="ml-auto hidden md:block">
          <ul className="flex items-center gap-2">
            {NAV.map((n) => (
              <li key={n.href}>
                <Link
                  href={n.href}
                  aria-current={isActive(n.href) ? "page" : undefined}
                  className={`rounded-full px-4 py-2 text-[0.95rem] font-extrabold transition ${
                    isActive(n.href) ? "bg-white text-blu-1" : "bg-white/15 text-white hover:bg-white/25"
                  }`}
                >
                  {n.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        <div className="ml-auto flex items-center gap-1 md:ml-2">
          <button
            type="button"
            onClick={() => {
              setSearch((s) => !s);
            }}
            aria-expanded={search}
            aria-controls="header-search"
            className="grid h-11 w-11 place-items-center rounded-full bg-white/15 text-white transition hover:bg-white/25"
          >
            <Icon name={search ? "close" : "search"} />
            <span className="sr-only">{search ? "Chiudi ricerca" : "Apri ricerca"}</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setMenu((m) => !m);
            }}
            aria-expanded={menu}
            aria-controls="mobile-menu"
            className="grid h-11 w-11 place-items-center rounded-full bg-white/15 text-white transition hover:bg-white/25 md:hidden"
          >
            <Icon name={menu ? "close" : "menu"} />
            <span className="sr-only">{menu ? "Chiudi menu" : "Apri menu"}</span>
          </button>
        </div>
      </div>

      {search && (
        <div id="header-search" className="animate-rise px-4 pb-4 sm:px-6">
          <div className="mx-auto max-w-3xl">
            <SearchBox autoFocus onNavigate={() => setSearch(false)} />
          </div>
        </div>
      )}

      {menu && (
        <nav id="mobile-menu" aria-label="Menu mobile" className="animate-rise px-4 pb-4 md:hidden">
          <ul className="flex flex-col gap-2 py-2">
            {NAV.map((n) => (
              <li key={n.href}>
                <Link
                  href={n.href}
                  aria-current={isActive(n.href) ? "page" : undefined}
                  className={`flex items-center justify-between rounded-2xl px-4 py-3.5 text-base font-extrabold ${
                    isActive(n.href) ? "bg-white text-blu-1" : "bg-white/15 text-white"
                  }`}
                >
                  {n.label}
                  <Icon name="arrow" className="h-4 w-4" />
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      )}
    </header>
  );
}
