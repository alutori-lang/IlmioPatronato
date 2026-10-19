import Link from "next/link";
import { SearchBox } from "@/components/SearchBox";

export default function NotFound() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-20 text-center sm:px-6">
      <p className="text-sm font-medium text-brand">Errore 404</p>
      <h1 className="mt-4 text-3xl font-semibold text-ink">Pagina non trovata</h1>
      <p className="mt-3 text-lg text-ink-2">
        La pagina che cerchi non esiste o è stata spostata. Prova con la ricerca o parti da una di queste sezioni.
      </p>
      <div className="mt-8 text-left">
        <SearchBox />
      </div>
      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <Link href="/" className="rounded-xl bg-brand px-5 py-2.5 font-semibold text-brand-ink hover:bg-brand-2">
          Torna alla home
        </Link>
        <Link href="/bonus" className="rounded-xl border border-line px-5 py-2.5 font-semibold text-ink hover:bg-surface-2">
          Tutti i bonus
        </Link>
        <Link href="/calcolatori" className="rounded-xl border border-line px-5 py-2.5 font-semibold text-ink hover:bg-surface-2">
          Calcolatori
        </Link>
      </div>
    </div>
  );
}
