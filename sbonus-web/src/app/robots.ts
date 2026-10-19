import type { MetadataRoute } from "next";
import { absoluteUrl, INDEXABLE } from "@/lib/site";

export default function robots(): MetadataRoute.Robots {
  // Anteprime e indirizzi provvisori non vanno indicizzati (vedi INDEXABLE)
  if (!INDEXABLE) return { rules: [{ userAgent: "*", disallow: "/" }] };
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/admin", "/api/", "/cerca"] }],
    sitemap: absoluteUrl("/sitemap.xml"),
    host: absoluteUrl("/"),
  };
}
