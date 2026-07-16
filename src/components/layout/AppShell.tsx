import { Bell } from "@phosphor-icons/react"
import type { ReactNode } from "react"

interface AppShellProps {
  holderName?: string
  navigation: ReactNode
  children: ReactNode
}

export function AppShell({
  holderName,
  navigation,
  children,
}: AppShellProps) {
  const firstName = holderName?.split(" ")[0]

  return (
    <div className="nb-root">
      <div className="nb-layout">
        {navigation}

        <main className="nb-main">
          <header className="nb-topbar">
            <div className="nb-greeting">
              {firstName ? (
                <>
                  Welcome back, <strong>{firstName}</strong>
                </>
              ) : (
                <span aria-hidden="true">&nbsp;</span>
              )}
            </div>

            <div className="nb-topbar-icons">
              <button
                className="nb-icon-button"
                type="button"
                aria-label="Notifications"
              >
                <Bell size={19} />
              </button>
            </div>
          </header>

          {children}
        </main>
      </div>
    </div>
  )
}
