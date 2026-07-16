import { useState } from "react"
import { ViewRouter } from "../components/navigation/ViewRouter"
import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
import { ErrorState } from "../components/feedback/ErrorState"
import { Toast } from "../components/feedback/Toast"
import { AppShell } from "../components/layout/AppShell"
import { Navigation } from "../components/layout/Navigation"
import { useDashboard } from "../hooks/useDashboard"
import { useNavigationStore } from "../store/useNavigationStore"

export default function App() {
  const {
    status,
    dashboard,
    balanceVisible,
    toggleBalanceVisible,
    retry,
  } = useDashboard()

  const activeView = useNavigationStore((state) => state.activeView)
  const setActiveView = useNavigationStore((state) => state.setActiveView)
  const [toast, setToast] = useState<string | null>(null)

  return (
    <AppShell
      navigation={
        <Navigation
          activeView={activeView}
          onNavigate={setActiveView}
        />
      }
      holderName={dashboard?.account.holderName}
    >
      {(status === "idle" || status === "loading") && <DashboardSkeleton />}

      {status === "error" && <ErrorState onRetry={retry} />}

      {status === "success" && dashboard && (
        <ViewRouter
          activeView={activeView}
          dashboard={dashboard}
          balanceVisible={balanceVisible}
          onToggleBalance={toggleBalanceVisible}
          onAction={setToast}
        />
      )}

      {toast && <Toast message={toast} onDismiss={() => setToast(null)} />}
    </AppShell>
  )
}
