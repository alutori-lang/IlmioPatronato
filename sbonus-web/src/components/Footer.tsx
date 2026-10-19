import Link from "next/link";
import { SITE, APP } from "@/lib/site";
import { CALCOLATORI } from "@/lib/calcolatori";
import { CATEGORIE } from "@/lib/categories";
import { bonusPubblicati } from "@/lib/content";
import { Logo } from "./Logo";
import { CookiePrefsLink } from "./CookiePrefsLink";

export function Footer() {
  const categorieAttive = CATEGORIE.filter((c) => bonusPubblicati.some((b) => b.categoria === c.slug)).slice(0, 6);
  const anno = new Date().getFullYear();
  const col = "space-y-2.5 text-[0.95rem]";
  const link = "text-white/70 transition hover:text-white";
  return (
    <footer className="band-dark mt-24 text-white">
      <div className="mx-auto grid max-w-6xl gap-10 px-4 py-12 sm:grid-cols-2 sm:px-6 lg:grid-cols-[1.4fr_1fr_1fr_1fr]">
        <div>
          <Logo chiaro />
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-white/75">{SITE.slogan}</p>
          <p className="mt-4 max-w-xs text-xs leading-relaxed text-white/50">
            SBonus è un portale informativo indipendente. Non è un sito ufficiale e non è affiliato a INPS, Agenzia delle Entrate,
            Ministeri o altri enti pubblici. Le domande si presentano solo sui canali ufficiali.
          </p>
        </div>
        <nav aria-label="Bonus per categoria">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-[#7df3c4]">Bonus</h2>
          <ul className={col}>
            {categorieAttive.map((c) => (
              <li key={c.slug}>
                <Link href={`/categorie/${c.slug}`} className={link}>
                  {c.nome}
                </Link>
              </li>
            ))}
            <li>
              <Link href="/bonus" className={`${link} font-semibold`}>
                Tutti i bonus
              </Link>
            </li>
          </ul>
        </nav>
        <nav aria-label="Calcolatori">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-[#7df3c4]">Calcolatori</h2>
          <ul className={col}>
            {CALCOLATORI.map((c) => (
              <li key={c.slug}>
                <Link href={`/calcolatori/${c.slug}`} className={link}>
                  {c.titoloBreve}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <nav aria-label="Informazioni">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-[#7df3c4]">SBonus</h2>
          <ul className={col}>
            <li><Link href="/guide" className={link}>Guide</Link></li>
            <li><Link href="/chi-siamo" className={link}>Chi siamo</Link></li>
            <li><Link href="/contatti" className={link}>Contatti</Link></li>
            <li><Link href="/app" className={link}>App {APP.name}</Link></li>
            <li><Link href="/disclaimer" className={link}>Disclaimer</Link></li>
          </ul>
        </nav>
      </div>
      <div className="border-t border-white/10">
        <div className="mx-auto flex max-w-6xl flex-col gap-3 px-4 py-6 text-sm text-white/55 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <p>
            © {anno} {SITE.name} · Editore: {SITE.editor.name}
          </p>
          <ul className="flex flex-wrap gap-x-5 gap-y-2">
            <li><Link href="/privacy" className="hover:text-white">Privacy</Link></li>
            <li><Link href="/cookie" className="hover:text-white">Cookie</Link></li>
            <li><Link href="/termini" className="hover:text-white">Termini di utilizzo</Link></li>
            <li><CookiePrefsLink className="hover:text-white" /></li>
          </ul>
        </div>
      </div>
    </footer>
  );
}
