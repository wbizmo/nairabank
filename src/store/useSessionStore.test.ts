import { beforeEach, describe, expect, it } from "vitest"
import { useSessionStore } from "./useSessionStore"

describe("useSessionStore", () => {
  beforeEach(() => {
    window.sessionStorage.clear()

    useSessionStore.setState({
      status: "active",
      logoutDialogOpen: false,
    })
  })

  it("does not terminate the session until logout is confirmed", () => {
    useSessionStore.getState().requestLogout()

    expect(useSessionStore.getState().status).toBe("active")
    expect(useSessionStore.getState().logoutDialogOpen).toBe(true)

    useSessionStore.getState().confirmLogout()

    expect(useSessionStore.getState().status).toBe("signed-out")
    expect(useSessionStore.getState().logoutDialogOpen).toBe(false)
  })

  it("restores the demonstration session", () => {
    useSessionStore.getState().confirmLogout()
    useSessionStore.getState().restoreSession()

    expect(useSessionStore.getState().status).toBe("active")
    expect(
      window.sessionStorage.getItem("nairabank.demo-session"),
    ).toBeNull()
  })
})
