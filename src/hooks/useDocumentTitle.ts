import { useEffect } from "react"
import { navigationItems } from "../config/navigation"
import type { DashboardView } from "../domain/navigation"

export function useDocumentTitle(activeView: DashboardView) {
  useEffect(() => {
    const view = navigationItems.find((item) => item.id === activeView)
    document.title = view
      ? `${view.label} · NairaBank`
      : "NairaBank"
  }, [activeView])
}
