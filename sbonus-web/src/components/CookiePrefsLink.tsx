"use client";

import { apriPreferenze } from "./consent";

export function CookiePrefsLink({ className = "font-semibold text-brand underline underline-offset-2" }: { className?: string }) {
  return (
    <button type="button" onClick={apriPreferenze} className={className}>
      Preferenze cookie
    </button>
  );
}
