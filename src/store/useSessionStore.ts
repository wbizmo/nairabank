import { create } from "zustand"

const STORAGE_KEY = "nairabank.demo-session"

type SessionStatus = "active" | "signed-out"

function initialStatus(): SessionStatus {
  return window.sessionStorage.getItem(STORAGE_KEY) === "signed-out"
    ? "signed-out"
    : "active"
}

interface SessionState {
  status: SessionStatus
  logoutDialogOpen: boolean
  requestLogout: () => void
  cancelLogout: () => void
  confirmLogout: () => void
  restoreSession: () => void
}

export const useSessionStore = create<SessionState>((set) => ({
  status: initialStatus(),
  logoutDialogOpen: false,

  requestLogout: () => {
    set({ logoutDialogOpen: true })
  },

  cancelLogout: () => {
    set({ logoutDialogOpen: false })
  },

  confirmLogout: () => {
    window.sessionStorage.setItem(STORAGE_KEY, "signed-out")

    set({
      status: "signed-out",
      logoutDialogOpen: false,
    })
  },

  restoreSession: () => {
    window.sessionStorage.removeItem(STORAGE_KEY)

    set({
      status: "active",
      logoutDialogOpen: false,
    })
  },
}))
