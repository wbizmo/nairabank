import type { DashboardData } from "../../domain/dashboard"
import type { DashboardView } from "../../domain/navigation"
import { CardsView } from "../../features/cards/CardsView"
import { OverviewView } from "../../features/overview/OverviewView"
import { SettingsView } from "../../features/settings/SettingsView"
import { TransfersView } from "../../features/transfers/TransfersView"

interface ViewRouterProps {
  activeView: DashboardView
  dashboard: DashboardData
  balanceVisible: boolean
  onToggleBalance: () => void
  onAction: (message: string) => void
}

export function ViewRouter({
  activeView,
  dashboard,
  balanceVisible,
  onToggleBalance,
  onAction,
}: ViewRouterProps) {
  switch (activeView) {
    case "cards":
      return <CardsView />

    case "transfers":
      return <TransfersView />

    case "settings":
      return <SettingsView />

    case "overview":
    default:
      return (
        <OverviewView
          dashboard={dashboard}
          balanceVisible={balanceVisible}
          onToggleBalance={onToggleBalance}
          onAction={onAction}
        />
      )
  }
}
