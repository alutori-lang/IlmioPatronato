"use client";

import { apriPreferenze } from "./consent";

export function CookiePrefsLink() {
  return (
    <button type="button" onClick={apriPreferenze} className="hover:text-brand">
      Preferenze cookie
    </button>
  );
}
