import {
  CreditCard,
  Eye,
  Lock,
  Plus,
  Snowflake,
} from "@phosphor-icons/react"

const cardActions = [
  {
    label: "Freeze card",
    description: "Temporarily prevent new transactions",
    icon: Snowflake,
  },
  {
    label: "Card security",
    description: "Review PIN and online payment controls",
    icon: Lock,
  },
  {
    label: "View details",
    description: "Inspect masked card information",
    icon: Eye,
  },
]

export function CardsView() {
  return (
    <section className="nb-view" aria-labelledby="cards-view-title">
      <header className="nb-view-header">
        <div>
          <p className="nb-view-eyebrow">Payment instruments</p>
          <h1 id="cards-view-title">Cards</h1>
          <p>Manage your NairaBank physical and virtual cards.</p>
        </div>

        <button className="nb-primary-button" type="button">
          <Plus size={18} />
          Request card
        </button>
      </header>

      <div className="nb-view-grid">
        <article className="nb-bank-card">
          <div className="nb-bank-card-top">
            <span className="nb-logo nb-logo-card">
              naira<span>bank</span>
            </span>
            <CreditCard size={24} />
          </div>

          <div className="nb-card-number">5399 •••• •••• 7465</div>

          <div className="nb-bank-card-bottom">
            <div>
              <span>Cardholder</span>
              <strong>Amara Chukwu</strong>
            </div>
            <div>
              <span>Expires</span>
              <strong>07/30</strong>
            </div>
          </div>
        </article>

        <article className="nb-panel">
          <p className="nb-panel-title">Card controls</p>

          <div className="nb-setting-list">
            {cardActions.map(({ label, description, icon: Icon }) => (
              <button className="nb-setting-row" key={label} type="button">
                <span className="nb-setting-icon">
                  <Icon size={19} />
                </span>
                <span className="nb-setting-copy">
                  <strong>{label}</strong>
                  <small>{description}</small>
                </span>
                <span aria-hidden="true">›</span>
              </button>
            ))}
          </div>
        </article>
      </div>
    </section>
  )
}
