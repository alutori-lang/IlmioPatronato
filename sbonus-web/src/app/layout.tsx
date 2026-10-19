import type { Metadata, Viewport } from "next";
import { Nunito } from "next/font/google";
import "./globals.css";
import { SITE, APP, INDEXABLE, absoluteUrl } from "@/lib/site";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { CookieBanner } from "@/components/CookieBanner";
import { JsonLd } from "@/components/JsonLd";

const nunito = Nunito({ variable: "--font-nunito", subsets: ["latin"], weight: ["500", "600", "700", "800", "900"], display: "swap" });

export const metadata: Metadata = {
  metadataBase: new URL(SITE.url),
  title: {
    default: "SBonus – Bonus, agevolazioni e calcolatori 2026",
    template: "%s | SBonus",
  },
  description:
    "Guide aggiornate su bonus, agevolazioni INPS, ISEE, NASpI e Assegno Unico, con calcolatori gratuiti. Portale informativo indipendente.",
  applicationName: SITE.name,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    locale: SITE.locale,
    siteName: SITE.fullName,
    url: "/",
  },
  twitter: { card: "summary_large_image" },
  robots: INDEXABLE ? { index: true, follow: true } : { index: false, follow: false },
  itunes: { appId: APP.iosId },
  formatDetection: { telephone: false },
};

export const viewport: Viewport = {
  themeColor: "#ffd43b",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="it" className={`${nunito.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col">
        <JsonLd
          data={[
            {
              "@context": "https://schema.org",
              "@type": "WebSite",
              name: SITE.fullName,
              alternateName: SITE.name,
              url: absoluteUrl("/"),
              inLanguage: "it-IT",
              potentialAction: {
                "@type": "SearchAction",
                target: { "@type": "EntryPoint", urlTemplate: `${absoluteUrl("/cerca")}?q={search_term_string}` },
                "query-input": "required name=search_term_string",
              },
            },
            {
              "@context": "https://schema.org",
              "@type": "Organization",
              name: SITE.name,
              url: absoluteUrl("/"),
              logo: absoluteUrl("/icon.svg"),
              email: SITE.editor.email,
            },
          ]}
        />
        <Header />
        <main id="contenuto" className="flex-1">
          {children}
        </main>
        <Footer />
        <CookieBanner />
      </body>
    </html>
  );
}
