import {
  CreditCard,
  Gear,
  House,
  SignOut,
  Swap,
} from "@phosphor-icons/react"
import { navigationItems } from "../../config/navigation"
import type { DashboardView } from "../../domain/navigation"

const icons = {
  overview: House,
  cards: CreditCard,
  transfers: Swap,
  settings: Gear,
}

interface NavigationProps {
  activeView: DashboardView
  onNavigate: (view: DashboardView) => void
  onLogout?: () => void
}

export function Navigation({
  activeView,
  onNavigate,
  onLogout,
}: NavigationProps) {
  return (
    <>
      <aside className="nb-sidebar">
        <div className="nb-logo">
          naira<span>bank</span>
        </div>

        <nav className="nb-nav" aria-label="Primary navigation">
          {navigationItems.map((item) => {
            const Icon = icons[item.id]

            return (
              <button
                key={item.id}
                className={
                  "nb-nav-item" +
                  (activeView === item.id ? " active" : "")
                }
                type="button"
                aria-current={activeView === item.id ? "page" : undefined}
                onClick={() => onNavigate(item.id)}
              >
                <Icon size={18} />
                {item.label}
              </button>
            )
          })}
        </nav>

        {onLogout && (
          <button
            className="nb-nav-item nb-logout-button"
            type="button"
            onClick={onLogout}
          >
            <SignOut size={18} />
            Log out
          </button>
        )}
      </aside>

      <nav className="nb-bottom-tabs" aria-label="Mobile navigation">
        {navigationItems.map((item) => {
          const Icon = icons[item.id]

          return (
            <button
              key={item.id}
              className={
                "nb-tab-item" +
                (activeView === item.id ? " active" : "")
              }
              type="button"
              aria-current={activeView === item.id ? "page" : undefined}
              onClick={() => onNavigate(item.id)}
            >
              <Icon size={20} />
              {item.label}
            </button>
          )
        })}
      </nav>
    </>
  )
}
