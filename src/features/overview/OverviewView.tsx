import type { DashboardData } from "../../domain/dashboard"
import { BalanceHero } from "../../components/dashboard/BalanceHero"
import { QuickActions } from "../../components/dashboard/QuickActions"
import { SpendingChart } from "../../components/dashboard/SpendingChart"
import { TransactionList } from "../../components/dashboard/TransactionList"
import { TransferLimits } from "../../components/dashboard/TransferLimits"

interface OverviewViewProps {
  dashboard: DashboardData
  balanceVisible: boolean
  onToggleBalance: () => void
  onAction: (message: string) => void
}

export function OverviewView({
  dashboard,
  balanceVisible,
  onToggleBalance,
  onAction,
}: OverviewViewProps) {
  return (
    <section aria-label="Account overview">
      <BalanceHero
        account={dashboard.account}
        trend={dashboard.trend}
        visible={balanceVisible}
        onToggleVisible={onToggleBalance}
      />

      <QuickActions onAction={onAction} />

      <div className="nb-grid">
        <TransactionList transactions={dashboard.transactions} />

        <div className="nb-side-stack">
          <SpendingChart categories={dashboard.categories} />
          <TransferLimits account={dashboard.account} />
        </div>
      </div>
    </section>
  )
}
