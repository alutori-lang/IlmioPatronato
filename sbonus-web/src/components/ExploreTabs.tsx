"use client";

import Link from "next/link";
import { useId, useRef, useState } from "react";
import type { BonusLite } from "@/lib/content-shared";
import { stileTono } from "@/lib/categories";
import type { IconName } from "@/lib/categories";
import { BonusCard } from "./Cards";
import { Icon } from "./Icon";

export type Tab = { slug: string; nome: string; icona: IconName; bonus: BonusLite[] };

/** Tab per esigenza: mostra i bonus di una categoria alla volta, senza ripetizioni. */
export function ExploreTabs({ tabs }: { tabs: Tab[] }) {
  const id = useId();
  const [attiva, setAttiva] = useState(0);
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  const tab = tabs[attiva];

  const onKey = (e: React.KeyboardEvent, i: number) => {
    const n = e.key === "ArrowRight" ? (i + 1) % tabs.length : e.key === "ArrowLeft" ? (i - 1 + tabs.length) % tabs.length : -1;
    if (n < 0) return;
    e.preventDefault();
    setAttiva(n);
    refs.current[n]?.focus();
  };

  return (
    <div>
      <div role="tablist" aria-label="Categorie" className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 pb-1 sm:mx-0 sm:flex-wrap sm:px-0">
        {tabs.map((t, i) => {
          const on = i === attiva;
          return (
            <button
              key={t.slug}
              ref={(el) => {
                refs.current[i] = el;
              }}
              id={`${id}-tab-${i}`}
              role="tab"
              type="button"
              aria-selected={on}
              aria-controls={`${id}-panel`}
              tabIndex={on ? 0 : -1}
              onClick={() => setAttiva(i)}
              onKeyDown={(e) => onKey(e, i)}
              style={stileTono(t.slug)}
              className={`flex shrink-0 items-center gap-2.5 rounded-2xl border px-4 py-2.5 text-[0.95rem] font-semibold transition ${
                on ? "tone-icon border-transparent" : "border-line bg-surface text-ink-2 hover:text-ink"
              }`}
            >
              <Icon name={t.icona} className={`h-5 w-5 ${on ? "" : "tone-text"}`} />
              {t.nome}
              <span className={`rounded-full px-2 py-0.5 text-xs ${on ? "bg-white/25" : "bg-surface-2 text-ink-3"}`}>{t.bonus.length}</span>
            </button>
          );
        })}
      </div>
      <div id={`${id}-panel`} role="tabpanel" aria-labelledby={`${id}-tab-${attiva}`} className="mt-6">
        <div key={tab.slug} className="animate-rise grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {tab.bonus.slice(0, 6).map((b) => (
            <BonusCard key={b.slug} b={b} />
          ))}
        </div>
        <div className="mt-6 text-center">
          <Link href={`/categorie/${tab.slug}`} className="inline-flex items-center gap-1.5 font-semibold text-brand hover:underline">
            Tutto su {tab.nome.toLowerCase()} <Icon name="arrow" className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}
