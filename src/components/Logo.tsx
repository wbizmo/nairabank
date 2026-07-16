export function Logo() {
  return (
    <div style={{ display: "flex", alignItems: "baseline", gap: 2 }}>
      <span
        style={{
          fontWeight: 800,
          fontSize: 20,
          letterSpacing: "-0.02em",
          color: "var(--text)",
        }}
      >
        naira
      </span>
      <span
        style={{
          fontWeight: 800,
          fontSize: 20,
          letterSpacing: "-0.02em",
          color: "var(--accent)",
        }}
      >
        bank
      </span>
    </div>
  )
}
