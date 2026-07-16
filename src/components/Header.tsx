import { Bell, UserCircle } from "@phosphor-icons/react"
import { Logo } from "./Logo"

export function Header({ holderName }: { holderName?: string }) {
  return (
    <header
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        marginBottom: 24,
      }}
    >
      <Logo />
      <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
        <Bell size={20} weight="thin" color="var(--text-dim)" />
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <UserCircle size={26} weight="thin" color="var(--text-dim)" />
          <span style={{ fontSize: 14, color: "var(--text-dim)" }}>
            {holderName ? `Hi, ${holderName.split(" ")[0]}` : ""}
          </span>
        </div>
      </div>
    </header>
  )
}
