import { SignOut, X } from "@phosphor-icons/react"

interface LogoutDialogProps {
  open: boolean
  onCancel: () => void
  onConfirm: () => void
}

export function LogoutDialog({
  open,
  onCancel,
  onConfirm,
}: LogoutDialogProps) {
  if (!open) {
    return null
  }

  return (
    <div
      className="nb-dialog-backdrop"
      role="presentation"
      onMouseDown={onCancel}
    >
      <section
        className="nb-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="logout-dialog-title"
        aria-describedby="logout-dialog-description"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="nb-dialog-header">
          <span className="nb-dialog-icon">
            <SignOut size={24} />
          </span>

          <button
            className="nb-dialog-close"
            type="button"
            aria-label="Close logout confirmation"
            onClick={onCancel}
          >
            <X size={19} />
          </button>
        </header>

        <h2 id="logout-dialog-title">Log out of NairaBank?</h2>

        <p id="logout-dialog-description">
          This demonstration does not use real authentication. Logging out
          clears the local demo session and returns you to the signed-out
          screen.
        </p>

        <div className="nb-dialog-actions">
          <button
            className="nb-secondary-button"
            type="button"
            onClick={onCancel}
          >
            Cancel
          </button>

          <button
            className="nb-danger-button"
            type="button"
            onClick={onConfirm}
          >
            <SignOut size={17} />
            Log out
          </button>
        </div>
      </section>
    </div>
  )
}
