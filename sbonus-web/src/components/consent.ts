"use client";

import { useSyncExternalStore } from "react";

// Consenso cookie salvato solo nel browser dell'utente. "necessari" è sempre
// attivo (preferenza stessa); "pubblicita" abilita AdSense, solo se configurato.
export type Consenso = { versione: 1; pubblicita: boolean; data: string };

const KEY = "sbonus-consenso";
const EVENT = "sbonus-consenso-change";
const OPEN_EVENT = "sbonus-consenso-apri";

function read(): Consenso | null {
  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return null;
    const c = JSON.parse(raw) as Consenso;
    return c && c.versione === 1 ? c : null;
  } catch {
    return null;
  }
}

let snapshot: Consenso | null | undefined;
function getSnapshot() {
  if (snapshot === undefined) snapshot = read();
  return snapshot;
}

function subscribe(cb: () => void) {
  const handler = () => {
    snapshot = read();
    cb();
  };
  window.addEventListener(EVENT, handler);
  window.addEventListener("storage", handler);
  return () => {
    window.removeEventListener(EVENT, handler);
    window.removeEventListener("storage", handler);
  };
}

/** undefined durante il rendering lato server, null se l'utente non ha ancora scelto. */
export function useConsenso(): Consenso | null | undefined {
  return useSyncExternalStore(subscribe, getSnapshot, () => undefined);
}

export function salvaConsenso(pubblicita: boolean) {
  const c: Consenso = { versione: 1, pubblicita, data: new Date().toISOString() };
  try {
    window.localStorage.setItem(KEY, JSON.stringify(c));
  } catch {
    // archiviazione non disponibile: la scelta vale solo per questa pagina
  }
  snapshot = c;
  window.dispatchEvent(new Event(EVENT));
}

export function apriPreferenze() {
  window.dispatchEvent(new Event(OPEN_EVENT));
}

export const CONSENSO_OPEN_EVENT = OPEN_EVENT;
