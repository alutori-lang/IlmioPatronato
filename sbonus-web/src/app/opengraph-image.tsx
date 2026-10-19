import { ImageResponse } from "next/og";

export const alt = "SBonus – Bonus, agevolazioni e calcolatori";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OgImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 72,
          background: "linear-gradient(135deg, #143aa6 0%, #1d4fd8 55%, #2a6af0 100%)",
          color: "white",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
          <div style={{ width: 96, height: 96, borderRadius: 26, background: "white", display: "flex", alignItems: "center", justifyContent: "center", color: "#1d4fd8", fontSize: 64, fontWeight: 800 }}>
            S
          </div>
          <div style={{ fontSize: 56, fontWeight: 800, display: "flex" }}>
            S<span style={{ color: "#9ff0cf" }}>Bonus</span>
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column" }}>
          <div style={{ fontSize: 68, fontWeight: 800, lineHeight: 1.1, maxWidth: 980 }}>Tutti i bonus, le agevolazioni e i calcolatori utili in un solo posto.</div>
          <div style={{ marginTop: 28, fontSize: 30, opacity: 0.85 }}>Guide e calcolatori 2026 con fonti ufficiali · sbonus.it</div>
        </div>
      </div>
    ),
    size,
  );
}
