import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"
import { LogoutDialog } from "./LogoutDialog"

describe("LogoutDialog", () => {
  it("requires explicit confirmation before logging out", async () => {
    const user = userEvent.setup()
    const onCancel = vi.fn()
    const onConfirm = vi.fn()

    render(
      <LogoutDialog
        open
        onCancel={onCancel}
        onConfirm={onConfirm}
      />,
    )

    expect(
      screen.getByRole("heading", {
        name: /log out of nairabank/i,
      }),
    ).toBeInTheDocument()

    await user.click(
      screen.getByRole("button", {
        name: /^log out$/i,
      }),
    )

    expect(onConfirm).toHaveBeenCalledTimes(1)
    expect(onCancel).not.toHaveBeenCalled()
  })
})
