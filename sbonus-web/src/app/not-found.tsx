import Link from "next/link";
import { SearchBox } from "@/components/SearchBox";

export default function NotFound() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-20 text-center sm:px-6">
      <p className="inline-block rounded-full bg-sun px-4 py-1 text-sm font-black text-ink">Errore 404</p>
      <h1 className="mt-4 text-4xl font-black text-ink">Pagina non trovata</h1>
      <p className="mt-3 text-lg text-ink-2">
        La pagina che cerchi non esiste o è stata spostata. Prova con la ricerca o parti da una di queste sezioni.
      </p>
      <div className="mt-8 text-left">
        <SearchBox />
      </div>
      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <Link href="/" className="rounded-full bg-coral px-6 py-3 font-black text-white hover:bg-coral-2">
          Torna alla home
        </Link>
        <Link href="/bonus" className="rounded-full border-2 border-ink px-6 py-3 font-black text-ink hover:bg-ink hover:text-sun">
          Tutti i bonus
        </Link>
        <Link href="/calcolatori" className="rounded-full border-2 border-ink px-6 py-3 font-black text-ink hover:bg-ink hover:text-sun">
          Calcolatori
        </Link>
      </div>
    </div>
  );
}
