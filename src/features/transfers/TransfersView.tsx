import {
  ArrowRight,
  Bank,
  ClockCounterClockwise,
  PaperPlaneTilt,
  UserCircle,
} from "@phosphor-icons/react"

const beneficiaries = [
  {
    name: "Olive Brown",
    bank: "NairaBank",
    account: "•••• 1082",
  },
  {
    name: "Chidi Okafor",
    bank: "GTBank",
    account: "•••• 9034",
  },
  {
    name: "Ada Williams",
    bank: "Access Bank",
    account: "•••• 4421",
  },
]

export function TransfersView() {
  return (
    <section className="nb-view" aria-labelledby="transfers-view-title">
      <header className="nb-view-header">
        <div>
          <p className="nb-view-eyebrow">Payments</p>
          <h1 id="transfers-view-title">Transfers</h1>
          <p>Send money securely to saved or new beneficiaries.</p>
        </div>
      </header>

      <div className="nb-view-grid">
        <article className="nb-panel">
          <div className="nb-feature-heading">
            <span className="nb-feature-icon">
              <PaperPlaneTilt size={22} />
            </span>
            <div>
              <h2>New transfer</h2>
              <p>Start a bank or NairaBank transfer.</p>
            </div>
          </div>

          <form
            className="nb-transfer-form"
            onSubmit={(event) => event.preventDefault()}
          >
            <label>
              <span>Recipient account</span>
              <input
                type="text"
                inputMode="numeric"
                maxLength={10}
                placeholder="Enter 10-digit account number"
              />
            </label>

            <label>
              <span>Bank</span>
              <select defaultValue="">
                <option value="" disabled>
                  Select recipient bank
                </option>
                <option>NairaBank</option>
                <option>Access Bank</option>
                <option>GTBank</option>
                <option>UBA</option>
                <option>Zenith Bank</option>
              </select>
            </label>

            <label>
              <span>Amount</span>
              <div className="nb-amount-field">
                <span>₦</span>
                <input type="number" min="100" placeholder="0.00" />
              </div>
            </label>

            <button className="nb-primary-button nb-full-button" type="submit">
              Continue
              <ArrowRight size={18} />
            </button>
          </form>
        </article>

        <article className="nb-panel">
          <div className="nb-panel-heading-row">
            <div>
              <p className="nb-panel-title">Recent beneficiaries</p>
            </div>
            <ClockCounterClockwise size={19} />
          </div>

          <div className="nb-beneficiary-list">
            {beneficiaries.map((beneficiary, index) => (
              <button
                className="nb-beneficiary"
                key={beneficiary.account}
                type="button"
              >
                <span className="nb-beneficiary-icon">
                  {index === 0 ? (
                    <UserCircle size={22} />
                  ) : (
                    <Bank size={20} />
                  )}
                </span>

                <span>
                  <strong>{beneficiary.name}</strong>
                  <small>
                    {beneficiary.bank} · {beneficiary.account}
                  </small>
                </span>

                <ArrowRight size={17} />
              </button>
            ))}
          </div>
        </article>
      </div>
    </section>
  )
}
