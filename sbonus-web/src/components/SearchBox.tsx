"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { cerca, type Documento } from "@/lib/search";
import { Icon } from "./Icon";

export const TIPO_LABEL: Record<Documento["tipo"], string> = {
  bonus: "Bonus",
  guida: "Guida",
  calcolatore: "Calcolatore",
  categoria: "Categoria",
  faq: "Domanda frequente",
};

let cache: Promise<Documento[]> | null = null;
export function caricaIndice(): Promise<Documento[]> {
  if (!cache) {
    cache = fetch("/search-index.json")
      .then((r) => (r.ok ? r.json() : []))
      .catch(() => {
        cache = null;
        return [];
      });
  }
  return cache;
}

type Props = {
  size?: "lg" | "md";
  autoFocus?: boolean;
  defaultValue?: string;
  onNavigate?: () => void;
  placeholder?: string;
};

/** Combobox ARIA con suggerimenti durante la digitazione e navigazione da tastiera. */
export function SearchBox({ size = "md", autoFocus, defaultValue = "", onNavigate, placeholder = "Cerca un bonus, una prestazione o una guida..." }: Props) {
  const router = useRouter();
  const id = useId();
  const listId = `${id}-list`;
  const [q, setQ] = useState(defaultValue);
  const [indice, setIndice] = useState<Documento[] | null>(null);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);

  const risultati = indice && q.trim().length >= 2 ? cerca(indice, q, 7) : [];

  const carica = useCallback(() => {
    if (!indice) caricaIndice().then(setIndice);
  }, [indice]);

  useEffect(() => {
    if (autoFocus) {
      inputRef.current?.focus();
      carica();
    }
  }, [autoFocus, carica]);

  const vai = (url: string) => {
    setOpen(false);
    onNavigate?.();
    router.push(url);
  };

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (active >= 0 && risultati[active]) return vai(risultati[active].url);
    const t = q.trim();
    if (t) vai(`/cerca?q=${encodeURIComponent(t)}`);
  };

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (!open || risultati.length === 0) {
      if (e.key === "ArrowDown") setOpen(true);
      return;
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setActive((a) => (a + 1) % risultati.length);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((a) => (a <= 0 ? risultati.length - 1 : a - 1));
    } else if (e.key === "Escape") {
      setOpen(false);
      setActive(-1);
    }
  };

  const big = size === "lg";
  const showList = open && q.trim().length >= 2;

  return (
    <form role="search" onSubmit={onSubmit} className="relative w-full" aria-label="Cerca nel sito">
      <label htmlFor={`${id}-input`} className="sr-only">
        Cerca nel sito
      </label>
      <div
        className={`flex items-center gap-2 rounded-2xl border border-line bg-surface shadow-sm transition focus-within:border-brand focus-within:shadow-md ${
          big ? "px-4 py-1.5 sm:px-5" : "px-3 py-1"
        }`}
      >
        <Icon name="search" className={big ? "h-6 w-6 shrink-0 text-ink-3" : "h-5 w-5 shrink-0 text-ink-3"} />
        <input
          ref={inputRef}
          id={`${id}-input`}
          type="search"
          role="combobox"
          aria-expanded={showList}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-activedescendant={active >= 0 ? `${id}-opt-${active}` : undefined}
          autoComplete="off"
          enterKeyHint="search"
          maxLength={100}
          value={q}
          placeholder={placeholder}
          onFocus={() => {
            carica();
            setOpen(true);
          }}
          onBlur={() => setTimeout(() => setOpen(false), 150)}
          onChange={(e) => {
            setQ(e.target.value);
            setActive(-1);
            setOpen(true);
          }}
          onKeyDown={onKeyDown}
          className={`min-w-0 flex-1 bg-transparent text-ink placeholder:text-ink-3 focus:outline-none [&::-webkit-search-cancel-button]:hidden ${
            big ? "py-3 text-base sm:text-lg" : "py-2 text-[0.95rem]"
          }`}
        />
        <button
          type="submit"
          className={`shrink-0 rounded-xl bg-brand font-semibold text-brand-ink transition hover:bg-brand-2 ${big ? "px-4 py-2.5 sm:px-5" : "px-3 py-1.5 text-sm"}`}
        >
          Cerca
        </button>
      </div>

      {showList && (
        <ul
          id={listId}
          role="listbox"
          aria-label="Suggerimenti"
          className="absolute inset-x-0 top-full z-50 mt-2 max-h-[60vh] overflow-auto rounded-2xl border border-line bg-surface p-1.5 text-left shadow-xl"
        >
          {indice === null && <li className="px-3 py-3 text-sm text-ink-3">Caricamento…</li>}
          {indice !== null && risultati.length === 0 && (
            <li className="px-3 py-3 text-sm text-ink-3">Nessun suggerimento. Premi Invio per cercare in tutto il sito.</li>
          )}
          {risultati.map((r, i) => (
            <li
              key={r.url}
              id={`${id}-opt-${i}`}
              role="option"
              aria-selected={i === active}
              onMouseDown={(e) => {
                e.preventDefault();
                vai(r.url);
              }}
              onMouseEnter={() => setActive(i)}
              className={`cursor-pointer rounded-xl px-3 py-2.5 ${i === active ? "bg-brand-soft" : ""}`}
            >
              <span className="block text-[0.7rem] font-semibold uppercase tracking-wide text-brand">{TIPO_LABEL[r.tipo]}</span>
              <span className="block font-medium text-ink">{r.titolo}</span>
            </li>
          ))}
        </ul>
      )}
    </form>
  );
}
