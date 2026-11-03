export default function HomePage() {
  return (
    <main style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "100vh", fontFamily: "'Work Sans', sans-serif" }}>
      <div style={{ textAlign: "center" }}>
        <h1 style={{ fontSize: 28, fontWeight: 700, color: "#1A1F36" }}>AXVN Holding Admin</h1>
        <p style={{ color: "#8F9BB3" }}>IP Asset Management · Whitelist · Governance</p>
        <p style={{ fontSize: 12, color: "#8F9BB3", marginTop: 8 }}>holding.${BRAND_DOMAIN} — AXVN TECH HOLDING JSC</p>
      </div>
    </main>
  );
}
