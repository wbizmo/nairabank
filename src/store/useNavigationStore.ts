import { create } from "zustand"
import type { DashboardView } from "../domain/navigation"

const STORAGE_KEY = "nairabank.active-view"

function readInitialView(): DashboardView {
  const stored = window.localStorage.getItem(STORAGE_KEY)

  if (
    stored === "overview" ||
    stored === "cards" ||
    stored === "transfers" ||
    stored === "settings"
  ) {
    return stored
  }

  return "overview"
}

interface NavigationState {
  activeView: DashboardView
  setActiveView: (view: DashboardView) => void
}

export const useNavigationStore = create<NavigationState>((set) => ({
  activeView: readInitialView(),
  setActiveView: (activeView) => {
    window.localStorage.setItem(STORAGE_KEY, activeView)
    set({ activeView })
  },
}))
