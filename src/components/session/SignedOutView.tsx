import { ArrowRight, ShieldCheck } from "@phosphor-icons/react"

interface SignedOutViewProps {
  onRestore: () => void
}

export function SignedOutView({ onRestore }: SignedOutViewProps) {
  return (
    <main className="nb-signed-out">
      <section className="nb-signed-out-card">
        <div className="nb-logo nb-signed-out-logo">
          naira<span>bank</span>
        </div>

        <span className="nb-signed-out-icon">
          <ShieldCheck size={34} />
        </span>

        <p className="nb-view-eyebrow">Session ended</p>
        <h1>You have been logged out</h1>

        <p>
          The local demonstration session has ended. No financial information
          or credentials were transmitted.
        </p>

        <button
          className="nb-primary-button nb-full-button"
          type="button"
          onClick={onRestore}
        >
          Return to dashboard
          <ArrowRight size={18} />
        </button>

        <small>Frontend demonstration only. No real banking session exists.</small>
      </section>
    </main>
  )
}
