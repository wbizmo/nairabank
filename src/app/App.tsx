import { useState } from "react"
import { ViewRouter } from "../components/navigation/ViewRouter"
import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
import { ErrorState } from "../components/feedback/ErrorState"
import { Toast } from "../components/feedback/Toast"
import { AppShell } from "../components/layout/AppShell"
import { Navigation } from "../components/layout/Navigation"
import { LogoutDialog } from "../components/session/LogoutDialog"
import { SignedOutView } from "../components/session/SignedOutView"
import { useDashboard } from "../hooks/useDashboard"
import { useDocumentTitle } from "../hooks/useDocumentTitle"
import { useNavigationStore } from "../store/useNavigationStore"
import { useSessionStore } from "../store/useSessionStore"

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

  const sessionStatus = useSessionStore((state) => state.status)
  const logoutDialogOpen = useSessionStore(
    (state) => state.logoutDialogOpen,
  )
  const requestLogout = useSessionStore((state) => state.requestLogout)
  const cancelLogout = useSessionStore((state) => state.cancelLogout)
  const confirmLogout = useSessionStore((state) => state.confirmLogout)
  const restoreSession = useSessionStore((state) => state.restoreSession)

  const [toast, setToast] = useState<string | null>(null)

  useDocumentTitle(activeView)

  if (sessionStatus === "signed-out") {
    return <SignedOutView onRestore={restoreSession} />
  }

  return (
    <>
      <AppShell
        navigation={
          <Navigation
            activeView={activeView}
            onNavigate={setActiveView}
            onLogout={requestLogout}
          />
        }
        holderName={dashboard?.account.holderName}
      >
        {(status === "idle" || status === "loading") && (
          <DashboardSkeleton />
        )}

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

        {toast && (
          <Toast
            message={toast}
            onDismiss={() => setToast(null)}
          />
        )}
      </AppShell>

      <LogoutDialog
        open={logoutDialogOpen}
        onCancel={cancelLogout}
        onConfirm={confirmLogout}
      />
    </>
  )
}
