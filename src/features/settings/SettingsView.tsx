import {
  Bell,
  CaretRight,
  DeviceMobile,
  Fingerprint,
  Gauge,
  ShieldCheck,
} from "@phosphor-icons/react"

const settings = [
  {
    label: "Transaction notifications",
    description: "Control debit and credit alerts",
    icon: Bell,
  },
  {
    label: "Transfer limits",
    description: "Review your daily and monthly allowances",
    icon: Gauge,
  },
  {
    label: "Security and biometrics",
    description: "Manage device authentication preferences",
    icon: Fingerprint,
  },
  {
    label: "Trusted devices",
    description: "Review devices with access to this account",
    icon: DeviceMobile,
  },
]

export function SettingsView() {
  return (
    <section className="nb-view" aria-labelledby="settings-view-title">
      <header className="nb-view-header">
        <div>
          <p className="nb-view-eyebrow">Account control</p>
          <h1 id="settings-view-title">Settings</h1>
          <p>Manage preferences and security controls.</p>
        </div>
      </header>

      <div className="nb-settings-layout">
        <article className="nb-panel">
          <p className="nb-panel-title">Account settings</p>

          <div className="nb-setting-list">
            {settings.map(({ label, description, icon: Icon }) => (
              <button className="nb-setting-row" key={label} type="button">
                <span className="nb-setting-icon">
                  <Icon size={19} />
                </span>

                <span className="nb-setting-copy">
                  <strong>{label}</strong>
                  <small>{description}</small>
                </span>

                <CaretRight size={17} />
              </button>
            ))}
          </div>
        </article>

        <aside className="nb-security-summary">
          <span>
            <ShieldCheck size={26} />
          </span>
          <div>
            <h2>Account protection</h2>
            <p>
              Your account currently uses device verification and transaction
              monitoring.
            </p>
          </div>
        </aside>
      </div>
    </section>
  )
}
