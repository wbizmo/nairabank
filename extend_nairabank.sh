#!/usr/bin/env bash

set -u
set -o pipefail

BASE_BRANCH="main"
CURRENT_STEP="startup"

notice() {
  printf '\n\033[1;36m==> %s\033[0m\n' "$1"
}

warning() {
  printf '\n\033[1;33m[warning] %s\033[0m\n' "$1"
}

fail() {
  printf '\n\033[1;31m[error] %s\033[0m\n' "$1"
  printf '\033[1;31m[error] Stopped during: %s\033[0m\n' "$CURRENT_STEP"
  return 1
}

run() {
  "$@" || fail "Command failed: $*"
}

commit_if_changed() {
  local message="$1"

  git add -A

  if git diff --cached --quiet; then
    warning "No staged changes for commit: $message"
    return 0
  fi

  run git commit -m "$message"
}

validate_project() {
  CURRENT_STEP="project validation"

  notice "Running lint"
  run npm run lint

  notice "Running type checks"
  run npm run typecheck

  notice "Running tests"
  run npm run test

  notice "Running production build"
  run npm run build
}

prepare_main() {
  CURRENT_STEP="preparing main"

  run git switch "$BASE_BRANCH"
  run git pull --ff-only origin "$BASE_BRANCH"

  if [ -n "$(git status --porcelain)" ]; then
    warning "Working tree contains uncommitted changes."
    git status --short
    return 1
  fi
}

wait_for_manual_merge() {
  local pr_url="$1"
  local branch="$2"

  printf '\n'
  printf '\033[1;32mPR created successfully:\033[0m\n'
  printf '%s\n\n' "$pr_url"
  printf 'Open the URL above and merge the PR manually on GitHub.\n'
  printf 'Do not delete this Codespaces terminal while completing the merge.\n\n'

  read -r -p "After the PR is merged on GitHub, press Enter here to continue: "

  CURRENT_STEP="verifying manual merge for $branch"

  run git switch "$BASE_BRANCH"
  run git pull --ff-only origin "$BASE_BRANCH"

  if gh pr view "$branch" --json state --jq '.state' 2>/dev/null | grep -q '^MERGED$'; then
    notice "Confirmed that $branch was merged"
  else
    warning "GitHub does not report $branch as merged yet."
    warning "The script will pause so the next branch is not created from stale main."
    return 1
  fi

  git branch -D "$branch" >/dev/null 2>&1 || true
  git push origin --delete "$branch" >/dev/null 2>&1 || true
}

create_pr() {
  local branch="$1"
  local title="$2"
  local body_file="$3"

  CURRENT_STEP="pushing $branch"
  run git push -u origin "$branch"

  CURRENT_STEP="opening pull request for $branch"

  local pr_url
  pr_url="$(
    gh pr create \
      --base "$BASE_BRANCH" \
      --head "$branch" \
      --title "$title" \
      --body-file "$body_file"
  )" || return 1

  wait_for_manual_merge "$pr_url" "$branch"
}

command -v git >/dev/null 2>&1 || {
  echo "git is required."
  exit 1
}

command -v gh >/dev/null 2>&1 || {
  echo "GitHub CLI is required."
  exit 1
}

command -v npm >/dev/null 2>&1 || {
  echo "npm is required."
  exit 1
}

gh auth status >/dev/null 2>&1 || {
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Run this script from the NairaBank repository root."
  exit 1
}

prepare_main || exit 1

mkdir -p \
  src/components/navigation \
  src/components/session \
  src/features/cards \
  src/features/overview \
  src/features/settings \
  src/features/transfers \
  src/store \
  docs

################################################################################
# PR 1: Functional SPA navigation
################################################################################

CURRENT_STEP="PR 1 application navigation"

notice "PR 1/3: implementing functional SPA navigation"

run git switch -c feat/spa-navigation

cat > src/domain/navigation.ts <<'EOF'
export type DashboardView =
  | "overview"
  | "cards"
  | "transfers"
  | "settings"

export interface NavigationItem {
  id: DashboardView
  label: string
  description: string
}
EOF

cat > src/config/navigation.ts <<'EOF'
import type { NavigationItem } from "../domain/navigation"

export const navigationItems: NavigationItem[] = [
  {
    id: "overview",
    label: "Overview",
    description: "Balances, recent activity, spending, and transfer limits",
  },
  {
    id: "cards",
    label: "Cards",
    description: "Manage physical and virtual payment cards",
  },
  {
    id: "transfers",
    label: "Transfers",
    description: "Send money and inspect recent beneficiaries",
  },
  {
    id: "settings",
    label: "Settings",
    description: "Control preferences, limits, and account security",
  },
]
EOF

cat > src/store/useNavigationStore.ts <<'EOF'
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
EOF

cat > src/features/cards/CardsView.tsx <<'EOF'
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
EOF

cat > src/features/transfers/TransfersView.tsx <<'EOF'
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
EOF

cat > src/features/settings/SettingsView.tsx <<'EOF'
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
EOF

cat > src/features/overview/OverviewView.tsx <<'EOF'
import type { DashboardData } from "../../domain/dashboard"
import { BalanceHero } from "../../components/dashboard/BalanceHero"
import { QuickActions } from "../../components/dashboard/QuickActions"
import { SpendingChart } from "../../components/dashboard/SpendingChart"
import { TransactionList } from "../../components/dashboard/TransactionList"
import { TransferLimits } from "../../components/dashboard/TransferLimits"

interface OverviewViewProps {
  dashboard: DashboardData
  balanceVisible: boolean
  onToggleBalance: () => void
  onAction: (message: string) => void
}

export function OverviewView({
  dashboard,
  balanceVisible,
  onToggleBalance,
  onAction,
}: OverviewViewProps) {
  return (
    <section aria-label="Account overview">
      <BalanceHero
        account={dashboard.account}
        trend={dashboard.trend}
        visible={balanceVisible}
        onToggleVisible={onToggleBalance}
      />

      <QuickActions onAction={onAction} />

      <div className="nb-grid">
        <TransactionList transactions={dashboard.transactions} />

        <div className="nb-side-stack">
          <SpendingChart categories={dashboard.categories} />
          <TransferLimits account={dashboard.account} />
        </div>
      </div>
    </section>
  )
}
EOF

cat > src/components/navigation/ViewRouter.tsx <<'EOF'
import type { DashboardData } from "../../domain/dashboard"
import type { DashboardView } from "../../domain/navigation"
import { CardsView } from "../../features/cards/CardsView"
import { OverviewView } from "../../features/overview/OverviewView"
import { SettingsView } from "../../features/settings/SettingsView"
import { TransfersView } from "../../features/transfers/TransfersView"

interface ViewRouterProps {
  activeView: DashboardView
  dashboard: DashboardData
  balanceVisible: boolean
  onToggleBalance: () => void
  onAction: (message: string) => void
}

export function ViewRouter({
  activeView,
  dashboard,
  balanceVisible,
  onToggleBalance,
  onAction,
}: ViewRouterProps) {
  switch (activeView) {
    case "cards":
      return <CardsView />

    case "transfers":
      return <TransfersView />

    case "settings":
      return <SettingsView />

    case "overview":
    default:
      return (
        <OverviewView
          dashboard={dashboard}
          balanceVisible={balanceVisible}
          onToggleBalance={onToggleBalance}
          onAction={onAction}
        />
      )
  }
}
EOF

cat > src/components/layout/Navigation.tsx <<'EOF'
import {
  CreditCard,
  Gear,
  House,
  SignOut,
  Swap,
} from "@phosphor-icons/react"
import { navigationItems } from "../../config/navigation"
import type { DashboardView } from "../../domain/navigation"

const icons = {
  overview: House,
  cards: CreditCard,
  transfers: Swap,
  settings: Gear,
}

interface NavigationProps {
  activeView: DashboardView
  onNavigate: (view: DashboardView) => void
  onLogout?: () => void
}

export function Navigation({
  activeView,
  onNavigate,
  onLogout,
}: NavigationProps) {
  return (
    <>
      <aside className="nb-sidebar">
        <div className="nb-logo">
          naira<span>bank</span>
        </div>

        <nav className="nb-nav" aria-label="Primary navigation">
          {navigationItems.map((item) => {
            const Icon = icons[item.id]

            return (
              <button
                key={item.id}
                className={
                  "nb-nav-item" +
                  (activeView === item.id ? " active" : "")
                }
                type="button"
                aria-current={activeView === item.id ? "page" : undefined}
                onClick={() => onNavigate(item.id)}
              >
                <Icon size={18} />
                {item.label}
              </button>
            )
          })}
        </nav>

        {onLogout && (
          <button
            className="nb-nav-item nb-logout-button"
            type="button"
            onClick={onLogout}
          >
            <SignOut size={18} />
            Log out
          </button>
        )}
      </aside>

      <nav className="nb-bottom-tabs" aria-label="Mobile navigation">
        {navigationItems.map((item) => {
          const Icon = icons[item.id]

          return (
            <button
              key={item.id}
              className={
                "nb-tab-item" +
                (activeView === item.id ? " active" : "")
              }
              type="button"
              aria-current={activeView === item.id ? "page" : undefined}
              onClick={() => onNavigate(item.id)}
            >
              <Icon size={20} />
              {item.label}
            </button>
          )
        })}
      </nav>
    </>
  )
}
EOF

python3 - <<'PY'
from pathlib import Path

path = Path("src/app/App.tsx")
text = path.read_text()

path.write_text("""import { useState } from "react"
import { ViewRouter } from "../components/navigation/ViewRouter"
import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
import { ErrorState } from "../components/feedback/ErrorState"
import { Toast } from "../components/feedback/Toast"
import { AppShell } from "../components/layout/AppShell"
import { Navigation } from "../components/layout/Navigation"
import { useDashboard } from "../hooks/useDashboard"
import { useNavigationStore } from "../store/useNavigationStore"

export default function App() {
  const {
    status,
    dashboard,
    balanceVisible,
    toggleBalanceVisible,
    retry,
  } = useDashboard()

  const activeView = useNavigationStore((state) => state.activeView)
  const setActiveView = useNavigationStore((state) => state.setActiveView)
  const [toast, setToast] = useState<string | null>(null)

  return (
    <AppShell
      navigation={
        <Navigation
          activeView={activeView}
          onNavigate={setActiveView}
        />
      }
      holderName={dashboard?.account.holderName}
    >
      {(status === "idle" || status === "loading") && <DashboardSkeleton />}

      {status === "error" && <ErrorState onRetry={retry} />}

      {status === "success" && dashboard && (
        <ViewRouter
          activeView={activeView}
          dashboard={dashboard}
          balanceVisible={balanceVisible}
          onToggleBalance={toggleBalanceVisible}
          onAction={setToast}
        />
      )}

      {toast && <Toast message={toast} onDismiss={() => setToast(null)} />}
    </AppShell>
  )
}
""")
PY

cat >> src/styles/global.css <<'EOF'

.nb-view {
  animation: nb-view-enter 160ms ease-out;
}

.nb-view-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 24px;
  margin-bottom: 22px;
}

.nb-view-header h1 {
  margin: 0;
  font-size: clamp(28px, 4vw, 40px);
  letter-spacing: -0.04em;
}

.nb-view-header p:not(.nb-view-eyebrow) {
  margin: 8px 0 0;
  color: var(--text-dim);
}

.nb-view-eyebrow {
  margin: 0 0 7px;
  color: var(--accent);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.nb-primary-button {
  display: inline-flex;
  min-height: 43px;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: 1px solid var(--accent);
  border-radius: 11px;
  background: var(--accent);
  color: #fff;
  padding: 0 16px;
  font-weight: 650;
  cursor: pointer;
}

.nb-primary-button:hover {
  background: #176f4c;
}

.nb-view-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.05fr) minmax(300px, 0.95fr);
  gap: 20px;
  align-items: start;
}

.nb-bank-card {
  min-height: 280px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border-radius: 22px;
  background:
    radial-gradient(circle at 83% 15%, rgba(255, 255, 255, 0.13), transparent 20%),
    linear-gradient(145deg, var(--hero), var(--hero-2));
  color: #eef4f0;
  padding: 26px;
  box-shadow: 0 22px 45px rgba(14, 42, 32, 0.18);
}

.nb-bank-card-top,
.nb-bank-card-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.nb-logo-card {
  padding: 0;
}

.nb-card-number {
  font-size: clamp(22px, 3vw, 31px);
  font-weight: 600;
  letter-spacing: 0.08em;
}

.nb-bank-card-bottom {
  align-items: flex-end;
}

.nb-bank-card-bottom div {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.nb-bank-card-bottom span {
  color: #aebdb4;
  font-size: 10px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.nb-bank-card-bottom strong {
  font-size: 13px;
}

.nb-setting-list,
.nb-beneficiary-list {
  display: flex;
  flex-direction: column;
}

.nb-setting-row,
.nb-beneficiary {
  display: flex;
  width: 100%;
  min-height: 68px;
  align-items: center;
  gap: 12px;
  border: 0;
  border-bottom: 1px solid var(--border);
  background: transparent;
  color: var(--text);
  padding: 10px 0;
  text-align: left;
  cursor: pointer;
}

.nb-setting-row:last-child,
.nb-beneficiary:last-child {
  border-bottom: 0;
}

.nb-setting-row:hover,
.nb-beneficiary:hover {
  color: var(--accent);
}

.nb-setting-icon,
.nb-beneficiary-icon,
.nb-feature-icon {
  display: grid;
  width: 40px;
  height: 40px;
  flex: 0 0 auto;
  place-items: center;
  border-radius: 11px;
  background: var(--accent-soft);
  color: var(--accent);
}

.nb-setting-copy,
.nb-beneficiary > span:nth-child(2) {
  display: flex;
  min-width: 0;
  flex: 1;
  flex-direction: column;
  gap: 4px;
}

.nb-setting-copy strong,
.nb-beneficiary strong {
  font-size: 13px;
}

.nb-setting-copy small,
.nb-beneficiary small {
  color: var(--text-dim);
  font-size: 11px;
}

.nb-feature-heading {
  display: flex;
  align-items: center;
  gap: 13px;
}

.nb-feature-heading h2 {
  margin: 0;
  font-size: 18px;
}

.nb-feature-heading p {
  margin: 4px 0 0;
  color: var(--text-dim);
  font-size: 12px;
}

.nb-transfer-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-top: 22px;
}

.nb-transfer-form label {
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.nb-transfer-form label > span {
  color: var(--text-dim);
  font-size: 12px;
  font-weight: 600;
}

.nb-transfer-form input,
.nb-transfer-form select {
  width: 100%;
  min-height: 44px;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: var(--surface);
  color: var(--text);
  padding: 0 12px;
}

.nb-amount-field {
  display: flex;
  align-items: center;
  border: 1px solid var(--border);
  border-radius: 10px;
}

.nb-amount-field > span {
  padding: 0 12px;
  color: var(--text-dim);
}

.nb-amount-field input {
  border: 0;
}

.nb-full-button {
  width: 100%;
  margin-top: 4px;
}

.nb-panel-heading-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.nb-settings-layout {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(260px, 0.6fr);
  gap: 20px;
  align-items: start;
}

.nb-security-summary {
  display: flex;
  align-items: flex-start;
  gap: 13px;
  border: 1px solid #b9d8c9;
  border-radius: 16px;
  background: var(--accent-soft);
  padding: 20px;
}

.nb-security-summary > span {
  color: var(--accent);
}

.nb-security-summary h2 {
  margin: 0;
  font-size: 15px;
}

.nb-security-summary p {
  margin: 7px 0 0;
  color: var(--text-dim);
  font-size: 12px;
  line-height: 1.55;
}

.nb-side-stack {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.nb-logout-button {
  margin-top: auto;
  color: #d9b7ae;
}

@keyframes nb-view-enter {
  from {
    opacity: 0;
    transform: translateY(4px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 860px) {
  .nb-view-grid,
  .nb-settings-layout {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 560px) {
  .nb-view-header {
    align-items: stretch;
    flex-direction: column;
  }

  .nb-view-header .nb-primary-button {
    width: 100%;
  }
}
EOF

cat > /tmp/nairabank-pr-1.md <<'EOF'
## Summary

Turns the existing dashboard navigation into a functional single-page application.

## Changes

- Adds persistent Overview, Cards, Transfers, and Settings views
- Introduces a dedicated navigation domain and Zustand navigation store
- Adds a view router instead of conditional UI inside the application shell
- Preserves the supplied desktop sidebar and mobile bottom navigation
- Adds card controls, transfer form structure, beneficiary history, and settings
- Persists the active view in localStorage
- Maintains responsive desktop, tablet, and mobile behavior

## Architecture

The navigation store owns only client-side view state. Dashboard server-like state remains isolated in the existing dashboard store and service layer.

## Validation

- npm run lint
- npm run typecheck
- npm run test
- npm run build
EOF

commit_if_changed "feat: add persistent SPA navigation and dashboard views"
validate_project

create_pr \
  "feat/spa-navigation" \
  "feat: add functional SPA navigation and dashboard views" \
  "/tmp/nairabank-pr-1.md" || exit 1

################################################################################
# PR 2: Logout workflow
################################################################################

CURRENT_STEP="PR 2 logout workflow"

notice "PR 2/3: implementing logout and session state"

run git switch -c feat/logout-workflow

cat > src/store/useSessionStore.ts <<'EOF'
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
EOF

cat > src/components/session/LogoutDialog.tsx <<'EOF'
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
EOF

cat > src/components/session/SignedOutView.tsx <<'EOF'
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
EOF

python3 - <<'PY'
from pathlib import Path

Path("src/app/App.tsx").write_text("""import { useState } from "react"
import { ViewRouter } from "../components/navigation/ViewRouter"
import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
import { ErrorState } from "../components/feedback/ErrorState"
import { Toast } from "../components/feedback/Toast"
import { AppShell } from "../components/layout/AppShell"
import { Navigation } from "../components/layout/Navigation"
import { LogoutDialog } from "../components/session/LogoutDialog"
import { SignedOutView } from "../components/session/SignedOutView"
import { useDashboard } from "../hooks/useDashboard"
import { useNavigationStore } from "../store/useNavigationStore"
import { useSessionStore } from "../store/useSessionStore"

export default function App() {
  const {
    status,
    dashboard,
    balanceVisible,
    toggleBalanceVisible,
    retry,
  } = useDashboard()

  const activeView = useNavigationStore((state) => state.activeView)
  const setActiveView = useNavigationStore((state) => state.setActiveView)

  const sessionStatus = useSessionStore((state) => state.status)
  const logoutDialogOpen = useSessionStore(
    (state) => state.logoutDialogOpen,
  )
  const requestLogout = useSessionStore((state) => state.requestLogout)
  const cancelLogout = useSessionStore((state) => state.cancelLogout)
  const confirmLogout = useSessionStore((state) => state.confirmLogout)
  const restoreSession = useSessionStore((state) => state.restoreSession)

  const [toast, setToast] = useState<string | null>(null)

  if (sessionStatus === "signed-out") {
    return <SignedOutView onRestore={restoreSession} />
  }

  return (
    <>
      <AppShell
        navigation={
          <Navigation
            activeView={activeView}
            onNavigate={setActiveView}
            onLogout={requestLogout}
          />
        }
        holderName={dashboard?.account.holderName}
      >
        {(status === "idle" || status === "loading") && (
          <DashboardSkeleton />
        )}

        {status === "error" && <ErrorState onRetry={retry} />}

        {status === "success" && dashboard && (
          <ViewRouter
            activeView={activeView}
            dashboard={dashboard}
            balanceVisible={balanceVisible}
            onToggleBalance={toggleBalanceVisible}
            onAction={setToast}
          />
        )}

        {toast && (
          <Toast
            message={toast}
            onDismiss={() => setToast(null)}
          />
        )}
      </AppShell>

      <LogoutDialog
        open={logoutDialogOpen}
        onCancel={cancelLogout}
        onConfirm={confirmLogout}
      />
    </>
  )
}
""")
PY

cat >> src/styles/global.css <<'EOF'

.nb-dialog-backdrop {
  position: fixed;
  inset: 0;
  z-index: 100;
  display: grid;
  place-items: center;
  background: rgba(9, 22, 17, 0.52);
  padding: 20px;
  backdrop-filter: blur(6px);
}

.nb-dialog {
  width: min(430px, 100%);
  border: 1px solid var(--border);
  border-radius: 20px;
  background: var(--surface);
  padding: 25px;
  box-shadow: 0 28px 80px rgba(9, 30, 22, 0.26);
}

.nb-dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.nb-dialog-icon {
  display: grid;
  width: 48px;
  height: 48px;
  place-items: center;
  border-radius: 13px;
  background: #f7ebe8;
  color: var(--danger);
}

.nb-dialog-close {
  display: grid;
  width: 38px;
  height: 38px;
  place-items: center;
  border: 1px solid var(--border);
  border-radius: 10px;
  background: transparent;
  color: var(--text-dim);
  cursor: pointer;
}

.nb-dialog h2 {
  margin: 22px 0 8px;
  font-size: 22px;
}

.nb-dialog > p {
  margin: 0;
  color: var(--text-dim);
  font-size: 13px;
  line-height: 1.65;
}

.nb-dialog-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 24px;
}

.nb-secondary-button,
.nb-danger-button {
  display: inline-flex;
  min-height: 43px;
  align-items: center;
  justify-content: center;
  gap: 7px;
  border-radius: 10px;
  padding: 0 14px;
  font-weight: 650;
  cursor: pointer;
}

.nb-secondary-button {
  border: 1px solid var(--border);
  background: var(--surface);
  color: var(--text);
}

.nb-danger-button {
  border: 1px solid var(--danger);
  background: var(--danger);
  color: #fff;
}

.nb-signed-out {
  display: grid;
  min-height: 100vh;
  place-items: center;
  background:
    radial-gradient(circle at 50% 5%, rgba(31, 138, 95, 0.13), transparent 32%),
    var(--bg);
  padding: 24px;
}

.nb-signed-out-card {
  width: min(440px, 100%);
  border: 1px solid var(--border);
  border-radius: 22px;
  background: var(--surface);
  padding: 32px;
  text-align: center;
  box-shadow: 0 24px 70px rgba(14, 42, 32, 0.12);
}

.nb-signed-out-logo {
  margin-bottom: 30px;
  color: var(--hero);
}

.nb-signed-out-icon {
  display: grid;
  width: 72px;
  height: 72px;
  place-items: center;
  margin: 0 auto 18px;
  border-radius: 50%;
  background: var(--accent-soft);
  color: var(--accent);
}

.nb-signed-out-card h1 {
  margin: 0;
  font-size: clamp(25px, 5vw, 34px);
  letter-spacing: -0.04em;
}

.nb-signed-out-card > p:not(.nb-view-eyebrow) {
  margin: 12px 0 24px;
  color: var(--text-dim);
  line-height: 1.65;
}

.nb-signed-out-card small {
  display: block;
  margin-top: 18px;
  color: var(--text-dim);
  font-size: 10px;
}
EOF

cat > src/components/session/LogoutDialog.test.tsx <<'EOF'
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
EOF

cat > /tmp/nairabank-pr-2.md <<'EOF'
## Summary

Adds the missing logout workflow and a clear signed-out state.

## Changes

- Adds a visible logout action to the desktop navigation
- Adds a confirmation dialog before session termination
- Adds a signed-out state with an explicit dashboard restoration action
- Stores only the simulated session status in sessionStorage
- Keeps authentication claims intentionally out of scope
- Adds automated confirmation-dialog coverage
- Preserves the existing dashboard data and navigation architecture

## Product boundary

NairaBank remains a frontend demonstration. The logout workflow simulates local session termination and does not claim to invalidate a server-side banking session.

## Validation

- npm run lint
- npm run typecheck
- npm run test
- npm run build
EOF

commit_if_changed "feat: add logout confirmation and signed-out session state"
validate_project

create_pr \
  "feat/logout-workflow" \
  "feat: add logout workflow and signed-out state" \
  "/tmp/nairabank-pr-2.md" || exit 1

################################################################################
# PR 3: Accessibility, route semantics, tests, and documentation
################################################################################

CURRENT_STEP="PR 3 navigation hardening"

notice "PR 3/3: hardening navigation and documentation"

run git switch -c chore/navigation-quality

cat > src/hooks/useDocumentTitle.ts <<'EOF'
import { useEffect } from "react"
import { navigationItems } from "../config/navigation"
import type { DashboardView } from "../domain/navigation"

export function useDocumentTitle(activeView: DashboardView) {
  useEffect(() => {
    const view = navigationItems.find((item) => item.id === activeView)
    document.title = view
      ? `${view.label} · NairaBank`
      : "NairaBank"
  }, [activeView])
}
EOF

python3 - <<'PY'
from pathlib import Path

path = Path("src/app/App.tsx")
text = path.read_text()

text = text.replace(
    'import { useDashboard } from "../hooks/useDashboard"',
    'import { useDashboard } from "../hooks/useDashboard"\nimport { useDocumentTitle } from "../hooks/useDocumentTitle"',
)

text = text.replace(
    '  const [toast, setToast] = useState<string | null>(null)',
    '  const [toast, setToast] = useState<string | null>(null)\n\n  useDocumentTitle(activeView)',
)

path.write_text(text)
PY

cat > src/store/useNavigationStore.test.ts <<'EOF'
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
EOF

cat > src/store/useSessionStore.test.ts <<'EOF'
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
EOF

cat > docs/NAVIGATION_AND_SESSION.md <<'EOF'
# Navigation and session model

## Purpose

NairaBank is a frontend banking-dashboard demonstration. The navigation and
session implementation is designed to behave credibly without claiming that a
real banking authentication system exists.

## Navigation ownership

The navigation store owns one value: the active dashboard view.

Supported views are:

- Overview
- Cards
- Transfers
- Settings

The active view is persisted in localStorage. This provides continuity after a
browser refresh without introducing a router dependency for four internal
dashboard views.

## Why no external router

The application is a single dashboard surface with no public deep links,
authentication routes, nested layouts, or server-side rendering.

A dedicated router would become appropriate if the application later added:

- Public and authenticated route groups
- URL-addressable account or transaction details
- Browser history navigation requirements
- Route-level data loaders
- Code-split pages
- Protected routes

For the current scope, a typed view identifier and explicit view router keep
the application smaller and easier to understand.

## Session simulation

The session store supports:

- Requesting logout
- Cancelling logout
- Confirming logout
- Restoring the demonstration session

The signed-out state is persisted in sessionStorage rather than localStorage.
Closing the browser session therefore resets the demonstration naturally.

## Security boundary

The current logout button does not:

- Revoke an access token
- Invalidate refresh tokens
- Contact a backend
- Destroy a server-side session
- Clear real financial information
- Perform device revocation

A production implementation must treat logout as a server-coordinated security
operation and must not rely on client-side state alone.

## Accessibility

The navigation exposes the active destination through aria-current.

The logout dialog includes:

- Dialog semantics
- Modal state
- Accessible title and description associations
- Explicit cancel and confirmation actions
- Keyboard-visible focus states

A production implementation should additionally include focus trapping and
restoration through a tested dialog primitive.
EOF

cat > docs/SPA_EXTENSION_GUIDE.md <<'EOF'
# SPA extension guide

## Adding a new view

1. Add the identifier to DashboardView.
2. Add its label and description to the navigation configuration.
3. Add the corresponding icon mapping.
4. Implement the feature view under src/features.
5. Add the view to ViewRouter.
6. Add navigation and rendering tests.

## State boundaries

Use the dashboard store for data that behaves like remote account data.

Use the navigation store only for view selection.

Use the session store only for the simulated session lifecycle.

Keep temporary form values inside their feature component unless multiple
unrelated components genuinely require them.

## Service boundaries

Feature components must not import dashboard.json directly.

All dashboard data must continue to pass through:

- HTTP client
- Dashboard service
- Dashboard store
- Dashboard hook
- Feature components

This preserves the ability to replace the JSON fixture with a real API without
rewriting presentation components.

## Avoiding premature architecture

Do not add Redux, React Router, a form framework, or a component system merely
because the application may need one later.

Introduce larger dependencies when the application demonstrates the
corresponding complexity, not in anticipation of hypothetical requirements.
EOF

cat > docs/LOGOUT_SECURITY_NOTES.md <<'EOF'
# Logout security notes

## Current implementation

The current logout feature is a local interaction model for the frontend
demonstration.

The confirmation step reduces accidental session termination and makes the
interaction explicit.

## Production requirements

A real banking logout operation should:

1. Revoke or rotate server-side credentials.
2. Invalidate refresh tokens.
3. Clear browser-held authentication material.
4. Terminate sensitive in-memory state.
5. Revalidate trusted-device state.
6. Write an auditable security event.
7. Redirect to a non-sensitive route.
8. Prevent protected data from being restored through browser history.
9. Consider logout propagation across multiple tabs.
10. Handle offline logout and delayed revocation safely.

## Why the demo does not fake these guarantees

Simulating token revocation solely in the browser would imply security behavior
that does not exist. The interface therefore states clearly that it terminates
only a local demonstration session.
EOF

cat > /tmp/nairabank-pr-3.md <<'EOF'
## Summary

Hardens the SPA navigation and simulated session implementation with tests, document titles, and detailed engineering documentation.

## Changes

- Updates the browser title when the active dashboard view changes
- Adds navigation-store persistence tests
- Adds session lifecycle tests
- Documents view ownership and state boundaries
- Documents why React Router is not yet required
- Documents production logout requirements and current limitations
- Adds a practical extension guide for future engineers

## Trade-off

The application deliberately uses a typed internal view router rather than introducing a route dependency for four non-addressable dashboard views.

## Validation

- npm run lint
- npm run typecheck
- npm run test
- npm run build
EOF

commit_if_changed "test: harden navigation persistence and session lifecycle"
commit_if_changed "docs: document SPA extension and logout security boundaries"
validate_project

create_pr \
  "chore/navigation-quality" \
  "chore: harden navigation, session tests, and engineering docs" \
  "/tmp/nairabank-pr-3.md" || exit 1

################################################################################
# Completion
################################################################################

CURRENT_STEP="completion"

notice "All three pull requests were created and manually merged"

run git switch "$BASE_BRANCH"
run git pull --ff-only origin "$BASE_BRANCH"

validate_project

printf '\n'
printf '\033[1;32mNairaBank extension completed successfully.\033[0m\n'
printf '\n'
printf 'Merged PRs created by this workflow:\n'

gh pr list \
  --state merged \
  --base "$BASE_BRANCH" \
  --limit 10 \
  --json number,title,url,headRefName \
  --template '{{range .}}{{if or (eq .headRefName "feat/spa-navigation") (eq .headRefName "feat/logout-workflow") (eq .headRefName "chore/navigation-quality")}}#{{.number}} {{.title}}{{"\n"}}{{.url}}{{"\n\n"}}{{end}}{{end}}'

printf 'Run the application locally with:\n'
printf 'npm run dev\n'
