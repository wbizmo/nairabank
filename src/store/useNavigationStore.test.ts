import { beforeEach, describe, expect, it } from "vitest"
import { useNavigationStore } from "./useNavigationStore"

describe("useNavigationStore", () => {
  beforeEach(() => {
    window.localStorage.clear()
    useNavigationStore.setState({
      activeView: "overview",
    })
  })

  it("changes and persists the active view", () => {
    useNavigationStore.getState().setActiveView("cards")

    expect(useNavigationStore.getState().activeView).toBe("cards")
    expect(
      window.localStorage.getItem("nairabank.active-view"),
    ).toBe("cards")
  })
})
