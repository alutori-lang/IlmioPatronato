import Link from "next/link";
import { absoluteUrl } from "@/lib/site";
import { JsonLd } from "./JsonLd";

export type Crumb = { label: string; href: string };

export function Breadcrumbs({ items, chiaro = false }: { items: Crumb[]; chiaro?: boolean }) {
  const all = [{ label: "Home", href: "/" }, ...items];
  return (
    <>
      <nav aria-label="Percorso" className={`text-sm ${chiaro ? "text-white/60" : "text-ink-3"}`}>
        <ol className="flex flex-wrap items-center gap-x-1.5 gap-y-1">
          {all.map((c, i) => (
            <li key={c.href} className="flex items-center gap-1.5">
              {i > 0 && <span aria-hidden="true">›</span>}
              {i === all.length - 1 ? (
                <span aria-current="page" className={`line-clamp-1 ${chiaro ? "text-white/90" : "text-ink-2"}`}>
                  {c.label}
                </span>
              ) : (
                <Link href={c.href} className={chiaro ? "hover:text-white hover:underline" : "hover:text-brand hover:underline"}>
                  {c.label}
                </Link>
              )}
            </li>
          ))}
        </ol>
      </nav>
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "BreadcrumbList",
          itemListElement: all.map((c, i) => ({ "@type": "ListItem", position: i + 1, name: c.label, item: absoluteUrl(c.href) })),
        }}
      />
    </>
  );
}
