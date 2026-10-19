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
    <header className="sticky top-0 z-40 border-b border-line/70 bg-surface/85 shadow-[0_1px_12px_rgba(15,27,51,0.05)] backdrop-blur-md supports-[backdrop-filter]:bg-surface/70">
      <a href="#contenuto" className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-3 focus:rounded-lg focus:bg-brand focus:px-4 focus:py-2 focus:text-brand-ink">
        Vai al contenuto
      </a>
      <div className="mx-auto flex h-16 max-w-6xl items-center gap-4 px-4 sm:px-6">
        <Link href="/" aria-label="SBonus, vai alla home" className="shrink-0">
          <Logo />
        </Link>

        <nav aria-label="Principale" className="ml-4 hidden md:block">
          <ul className="flex items-center gap-1">
            {NAV.map((n) => (
              <li key={n.href}>
                <Link
                  href={n.href}
                  aria-current={isActive(n.href) ? "page" : undefined}
                  className={`rounded-lg px-3 py-2 text-[0.95rem] font-medium transition ${
                    isActive(n.href) ? "bg-brand-soft text-brand" : "text-ink-2 hover:bg-surface-2 hover:text-ink"
                  }`}
                >
                  {n.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        <div className="ml-auto flex items-center gap-1">
          <Link
            href="/app"
            className="mr-1 hidden items-center gap-2 rounded-full bg-brand px-4 py-2 text-sm font-semibold text-brand-ink shadow-md shadow-brand/25 transition hover:bg-brand-2 lg:inline-flex"
          >
            <Icon name="phone" className="h-4 w-4" />
            Scarica l&apos;app
          </Link>
          <button
            type="button"
            onClick={() => {
              setSearch((s) => !s);
            }}
            aria-expanded={search}
            aria-controls="header-search"
            className="grid h-11 w-11 place-items-center rounded-xl text-ink-2 transition hover:bg-surface-2 hover:text-ink"
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
            className="grid h-11 w-11 place-items-center rounded-xl text-ink-2 transition hover:bg-surface-2 hover:text-ink md:hidden"
          >
            <Icon name={menu ? "close" : "menu"} />
            <span className="sr-only">{menu ? "Chiudi menu" : "Apri menu"}</span>
          </button>
        </div>
      </div>

      {search && (
        <div id="header-search" className="animate-rise border-t border-line bg-surface px-4 py-3 sm:px-6">
          <div className="mx-auto max-w-3xl">
            <SearchBox autoFocus onNavigate={() => setSearch(false)} />
          </div>
        </div>
      )}

      {menu && (
        <nav id="mobile-menu" aria-label="Menu mobile" className="animate-rise border-t border-line bg-surface px-4 pb-4 md:hidden">
          <ul className="flex flex-col py-2">
            {NAV.map((n) => (
              <li key={n.href}>
                <Link
                  href={n.href}
                  aria-current={isActive(n.href) ? "page" : undefined}
                  className={`flex items-center justify-between rounded-xl px-3 py-3.5 text-base font-medium ${
                    isActive(n.href) ? "bg-brand-soft text-brand" : "text-ink"
                  }`}
                >
                  {n.label}
                  <Icon name="arrow" className="h-4 w-4 text-ink-3" />
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      )}
    </header>
  );
}
