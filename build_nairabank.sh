#!/usr/bin/env bash
set -Eeuo pipefail

BASE_BRANCH="${BASE_BRANCH:-$(git branch --show-current 2>/dev/null || printf 'main')}"
[[ -n "$BASE_BRANCH" ]] || BASE_BRANCH="main"
SKIP_GITHUB="${NAIRABANK_SKIP_GITHUB:-0}"

log(){ printf '\n==> %s\n' "$1"; }
warn(){ printf '\n[warning] %s\n' "$1" >&2; }
trap 'warn "Stopped near line ${BASH_LINENO[0]} while running: ${BASH_COMMAND}"' ERR

for cmd in git node npm; do command -v "$cmd" >/dev/null 2>&1 || { warn "$cmd is required"; return 1 2>/dev/null || false; }; done
if [[ "$SKIP_GITHUB" != "1" ]]; then
  command -v gh >/dev/null 2>&1 || { warn "gh is required"; return 1 2>/dev/null || false; }
  gh auth status >/dev/null 2>&1 || { warn "Run gh auth login first"; return 1 2>/dev/null || false; }
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { warn "Run inside the target Codespaces repository"; return 1 2>/dev/null || false; }
[[ -z "$(git status --porcelain)" ]] || { warn "Working tree must be clean"; return 1 2>/dev/null || false; }

if git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then git checkout "$BASE_BRANCH"; else git checkout -b "$BASE_BRANCH"; fi
if git remote get-url origin >/dev/null 2>&1; then git pull --ff-only origin "$BASE_BRANCH" || warn "Could not fast-forward; continuing locally"; fi

git config user.name >/dev/null 2>&1 || git config user.name "wbizmo"
git config user.email >/dev/null 2>&1 || git config user.email "wbizmo@users.noreply.github.com"

commit_if_changed(){
  git add -A
  if git diff --cached --quiet; then warn "No changes for: $1"; else git commit -m "$1"; fi
}

validate(){
  npm run lint
  npm run typecheck
  npm run test
  npm run build
}

finish_pr(){
  local branch="$1" title="$2" body="$3"
  validate
  if [[ "$SKIP_GITHUB" == "1" ]]; then
    git checkout "$BASE_BRANCH"
    git merge --no-ff "$branch" -m "$title"
    git branch -D "$branch"
    return
  fi
  git push -u origin "$branch"
  local url
  url="$(gh pr create --base "$BASE_BRANCH" --head "$branch" --title "$title" --body-file "$body")"
  printf 'Opened %s\n' "$url"
  gh pr merge "$url" --merge --delete-branch
  git checkout "$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH"
}

log "Repository hygiene"
cat > .gitignore <<'EOF'
node_modules
dist
coverage
.vite
*.log
.env
.env.*
!.env.example
.DS_Store
EOF
cat > .editorconfig <<'EOF'
root = true
[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
[*.md]
trim_trailing_whitespace = false
EOF
commit_if_changed "chore: establish repository hygiene"
if [[ "$SKIP_GITHUB" != "1" ]] && git remote get-url origin >/dev/null 2>&1; then git push -u origin "$BASE_BRANCH"; fi

################################################################################
# PR 1: Foundation
################################################################################
log "PR 1/4: application foundation"
git checkout -b feat/application-foundation
mkdir -p src/app src/components/common src/styles src/test public docs

cat > package.json <<'EOF'
{
  "name": "nairabank",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "description": "Responsive Nigerian retail-banking dashboard simulation.",
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0",
    "lint": "eslint . --max-warnings=0",
    "typecheck": "tsc -b --pretty false",
    "test": "vitest run --pool=forks --maxWorkers=1 --minWorkers=1"
  },
  "dependencies": {
    "@phosphor-icons/react": "^2.1.7",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "recharts": "^2.12.7",
    "zustand": "^4.5.5"
  },
  "devDependencies": {
    "@eslint/js": "^9.17.0",
    "@testing-library/jest-dom": "^6.6.3",
    "@testing-library/react": "^16.1.0",
    "@testing-library/user-event": "^14.5.2",
    "@types/react": "^18.3.18",
    "@types/react-dom": "^18.3.5",
    "@vitejs/plugin-react": "^4.3.4",
    "eslint": "^9.17.0",
    "eslint-plugin-react-hooks": "^5.1.0",
    "eslint-plugin-react-refresh": "^0.4.16",
    "globals": "^15.14.0",
    "jsdom": "^25.0.1",
    "typescript": "^5.7.2",
    "typescript-eslint": "^8.18.2",
    "vite": "^5.4.11",
    "vitest": "^2.1.8"
  }
}
EOF
cat > tsconfig.json <<'EOF'
{"files":[],"references":[{"path":"./tsconfig.app.json"},{"path":"./tsconfig.node.json"}]}
EOF
cat > tsconfig.app.json <<'EOF'
{
  "compilerOptions": {
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.app.tsbuildinfo",
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
EOF
cat > tsconfig.node.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "Bundler",
    "isolatedModules": true,
    "noEmit": true,
    "strict": true
  },
  "include": ["vite.config.ts", "eslint.config.js"]
}
EOF
cat > vite.config.ts <<'EOF'
import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("recharts") || id.includes("d3-")) return "charts"
          if (id.includes("@phosphor-icons")) return "icons"
          if (id.includes("node_modules/react") || id.includes("node_modules/scheduler")) return "react-vendor"
          return undefined
        },
      },
    },
  },
  test: { environment: "jsdom", setupFiles: "./src/test/setup.ts", globals: true },
})
EOF
cat > eslint.config.js <<'EOF'
import js from "@eslint/js"
import globals from "globals"
import reactHooks from "eslint-plugin-react-hooks"
import reactRefresh from "eslint-plugin-react-refresh"
import tseslint from "typescript-eslint"

export default tseslint.config(
  { ignores: ["dist", "coverage"] },
  {
    files: ["**/*.{ts,tsx}"],
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    languageOptions: { ecmaVersion: 2022, globals: globals.browser },
    plugins: { "react-hooks": reactHooks, "react-refresh": reactRefresh },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "react-refresh/only-export-components": ["warn", { allowConstantExport: true }],
      "@typescript-eslint/consistent-type-imports": "error"
    },
  },
)
EOF
cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <meta name="theme-color" content="#0e2a20" />
    <meta name="description" content="NairaBank responsive retail banking dashboard simulation." />
    <title>NairaBank</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
cat > src/vite-env.d.ts <<'EOF'
/// <reference types="vite/client" />
EOF
cat > src/test/setup.ts <<'EOF'
import "@testing-library/jest-dom/vitest"
class ResizeObserverMock { observe(){} unobserve(){} disconnect(){} }
Object.defineProperty(globalThis, "ResizeObserver", { configurable: true, writable: true, value: ResizeObserverMock })
EOF
cat > src/main.tsx <<'EOF'
import { StrictMode } from "react"
import { createRoot } from "react-dom/client"
import { App } from "./app/App"
import "./styles/global.css"

const root = document.getElementById("root")
if (!root) throw new Error("Application root element was not found")
createRoot(root).render(<StrictMode><App /></StrictMode>)
EOF
cat > src/components/common/DashboardSkeleton.tsx <<'EOF'
export function DashboardSkeleton() {
  return <div aria-label="Loading dashboard" aria-busy="true">
    <div className="nb-skel nb-skel-hero" />
    <div className="nb-actions">{[0,1,2,3].map((item)=><div key={item} className="nb-skel nb-skel-action" />)}</div>
    <div className="nb-grid"><div className="nb-skel nb-skel-panel" /><div className="nb-skel nb-skel-panel" /></div>
  </div>
}
EOF
cat > src/app/App.tsx <<'EOF'
import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
export function App(){
  return <div className="nb-root"><div className="nb-layout"><aside className="nb-sidebar"><div className="nb-logo">naira<span>bank</span></div></aside><main className="nb-main"><div className="nb-topbar"><div className="nb-greeting">Loading your account</div></div><DashboardSkeleton /></main></div></div>
}
EOF
cat > src/styles/global.css <<'EOF'
:root{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:#10150f;background:#f4f5f1;font-synthesis:none;text-rendering:optimizeLegibility}
*{box-sizing:border-box}html{min-width:320px;background:#f4f5f1}body{margin:0;min-width:320px;min-height:100vh}button{font:inherit;cursor:pointer}
.nb-root{--bg:#f4f5f1;--surface:#fff;--border:#e2e4de;--text:#10150f;--text-dim:#676f63;--accent:#1f8a5f;--accent-soft:#e7f2eb;--gold:#b98b2e;--hero:#0e2a20;--hero-2:#143a2c;--danger:#b4442c;min-height:100vh;background:var(--bg);color:var(--text)}
.nb-root button:focus-visible{outline:2px solid var(--accent);outline-offset:2px}.nb-layout{display:flex;min-height:100vh}.nb-sidebar{width:232px;flex-shrink:0;background:var(--hero);color:#edefea;padding:24px 16px}.nb-logo{font-size:18px;font-weight:800;letter-spacing:-.01em;padding:0 8px}.nb-logo span{color:var(--gold)}.nb-main{flex:1;min-width:0;max-width:980px;padding:28px 32px 100px}.nb-topbar{display:flex;align-items:center;justify-content:space-between;margin-bottom:22px}.nb-greeting{min-height:22px;color:var(--text-dim);font-size:15px}.nb-actions{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:20px}.nb-grid{display:grid;grid-template-columns:1.3fr 1fr;gap:20px;align-items:start}.nb-skel{position:relative;overflow:hidden;border-radius:16px;background:#e8e9e4}.nb-skel:after{position:absolute;inset:0;content:"";transform:translateX(-100%);background:linear-gradient(90deg,transparent,rgba(255,255,255,.75),transparent);animation:nb-shimmer 1.4s infinite}.nb-skel-hero{height:176px;margin-bottom:20px}.nb-skel-action{height:78px}.nb-skel-panel{height:260px}@keyframes nb-shimmer{to{transform:translateX(100%)}}@media(prefers-reduced-motion:reduce){.nb-root *{animation:none!important;transition:none!important}}@media(max-width:1023px){.nb-sidebar{display:none}.nb-main{max-width:100%;padding:20px 20px 96px}}@media(max-width:860px){.nb-grid{grid-template-columns:1fr}}@media(max-width:560px){.nb-main{padding:18px 16px 92px}}
EOF
cat > src/app/App.test.tsx <<'EOF'
import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"
import { App } from "./App"
describe("App foundation",()=>{it("renders brand and loading state",()=>{render(<App/>);expect(screen.getByText("naira")).toBeInTheDocument();expect(screen.getByLabelText("Loading dashboard")).toBeInTheDocument()})})
EOF
npm install
commit_if_changed "chore: configure React TypeScript quality gates"
commit_if_changed "feat: establish responsive application shell and skeleton states"
cat > /tmp/nb-pr1.md <<'EOF'
## Summary
Establishes React, TypeScript, Vite, linting, tests, build checks, responsive shell, and skeleton loading states.
EOF
finish_pr feat/application-foundation "feat: establish NairaBank application foundation" /tmp/nb-pr1.md

################################################################################
# PR 2: Data architecture
################################################################################
log "PR 2/4: JSON API simulation and state architecture"
git checkout -b feat/dashboard-data-layer
mkdir -p src/domain src/services src/store src/hooks src/utils
cat > public/dashboard.json <<'EOF'
{
  "account":{"holderName":"Amara Chukwu","accountNumber":"0192837465","balance":482350.75,"dailyLimit":500000,"dailyUsed":76500,"monthlyLimit":5000000,"monthlyUsed":1875200},
  "trend":[40,44,42,48,46,52,58],
  "transactions":[
    {"id":"t1","merchant":"Salary - Zivora Systems","category":"Income","amount":650000,"kind":"credit","date":"2026-07-15","status":"successful"},
    {"id":"t2","merchant":"Jumia","category":"Shopping","amount":24500,"kind":"debit","date":"2026-07-15","status":"successful"},
    {"id":"t3","merchant":"Bolt","category":"Transport","amount":3200,"kind":"debit","date":"2026-07-14","status":"successful"},
    {"id":"t4","merchant":"DSTV Subscription","category":"Bills","amount":21500,"kind":"debit","date":"2026-07-13","status":"successful"},
    {"id":"t5","merchant":"Transfer to Olive B.","category":"Transfers","amount":40000,"kind":"debit","date":"2026-07-12","status":"successful"},
    {"id":"t6","merchant":"Chicken Republic","category":"Food","amount":8600,"kind":"debit","date":"2026-07-12","status":"successful"}
  ],
  "categories":[
    {"name":"Bills","value":36500,"color":"#B98B2E"},{"name":"Shopping","value":24500,"color":"#1F8A5F"},{"name":"Food","value":8600,"color":"#4C6B8A"},{"name":"Transport","value":3200,"color":"#B85C3E"},{"name":"Transfers","value":40000,"color":"#7A5C8A"}
  ]
}
EOF
cat > src/domain/dashboard.ts <<'EOF'
export type TransactionKind="credit"|"debit"
export type TransactionStatus="successful"|"pending"|"failed"
export type TransactionCategory="Income"|"Shopping"|"Transport"|"Bills"|"Transfers"|"Food"
export interface Account{holderName:string;accountNumber:string;balance:number;dailyLimit:number;dailyUsed:number;monthlyLimit:number;monthlyUsed:number}
export interface Transaction{id:string;merchant:string;category:TransactionCategory;amount:number;kind:TransactionKind;date:string;status:TransactionStatus}
export interface SpendingCategory{name:Exclude<TransactionCategory,"Income">;value:number;color:string}
export interface DashboardData{account:Account;trend:number[];transactions:Transaction[];categories:SpendingCategory[]}
EOF
cat > src/services/httpClient.ts <<'EOF'
export class HttpError extends Error{constructor(message:string,public readonly status:number){super(message);this.name="HttpError"}}
export async function getJson<T>(url:string,signal?:AbortSignal):Promise<T>{const response=await fetch(url,{headers:{Accept:"application/json"},signal});if(!response.ok)throw new HttpError(`Request failed with status ${response.status}`,response.status);return response.json() as Promise<T>}
EOF
cat > src/services/dashboardService.ts <<'EOF'
import type { DashboardData } from "../domain/dashboard"
import { getJson } from "./httpClient"
const DEFAULT_DELAY_MS=1100
function wait(ms:number,signal?:AbortSignal){return new Promise<void>((resolve,reject)=>{const timer=window.setTimeout(resolve,ms);signal?.addEventListener("abort",()=>{window.clearTimeout(timer);reject(new DOMException("The request was aborted","AbortError"))},{once:true})})}
export async function fetchDashboard(signal?:AbortSignal):Promise<DashboardData>{const params=new URLSearchParams(window.location.search);const parsed=Number(params.get("delay")??DEFAULT_DELAY_MS);await wait(Number.isFinite(parsed)?Math.max(0,parsed):DEFAULT_DELAY_MS,signal);if(params.get("simulateError")==="true")throw new Error("We could not load your account right now.");return getJson<DashboardData>("/dashboard.json",signal)}
EOF
cat > src/store/useDashboardStore.ts <<'EOF'
import { create } from "zustand"
import type { DashboardData } from "../domain/dashboard"
import { fetchDashboard } from "../services/dashboardService"
export type RequestStatus="idle"|"loading"|"success"|"error"
interface State{status:RequestStatus;data:DashboardData|null;error:string|null;balanceVisible:boolean;activeTab:string;load:()=>Promise<void>;retry:()=>Promise<void>;toggleBalance:()=>void;setActiveTab:(tab:string)=>void}
let controller:AbortController|null=null
export const useDashboardStore=create<State>((set,get)=>({status:"idle",data:null,error:null,balanceVisible:true,activeTab:"home",load:async()=>{controller?.abort();controller=new AbortController();set({status:"loading",error:null});try{const data=await fetchDashboard(controller.signal);set({data,status:"success",error:null})}catch(error){if(error instanceof DOMException&&error.name==="AbortError")return;set({status:"error",error:error instanceof Error?error.message:"Unexpected dashboard error"})}},retry:async()=>get().load(),toggleBalance:()=>set((s)=>({balanceVisible:!s.balanceVisible})),setActiveTab:(activeTab)=>set({activeTab})}))
EOF
cat > src/hooks/useDashboard.ts <<'EOF'
import { useEffect } from "react"
import { useDashboardStore } from "../store/useDashboardStore"
export function useDashboard(){const status=useDashboardStore((s)=>s.status);const data=useDashboardStore((s)=>s.data);const error=useDashboardStore((s)=>s.error);const load=useDashboardStore((s)=>s.load);const retry=useDashboardStore((s)=>s.retry);useEffect(()=>{if(status==="idle")void load()},[load,status]);return{status,data,error,retry}}
EOF
cat > src/utils/formatters.ts <<'EOF'
export function formatNaira(value:number,maximumFractionDigits=0){return new Intl.NumberFormat("en-NG",{style:"currency",currency:"NGN",maximumFractionDigits}).format(value)}
export function formatTransactionDate(value:string){return new Intl.DateTimeFormat("en-NG",{day:"numeric",month:"short"}).format(new Date(value))}
export function maskAccountNumber(value:string){return `**** ${value.slice(-4)}`}
export function percentage(used:number,limit:number){if(limit<=0)return 0;return Math.min(100,Math.max(0,(used/limit)*100))}
EOF
cat > src/utils/formatters.test.ts <<'EOF'
import { describe,expect,it } from "vitest"
import { maskAccountNumber,percentage } from "./formatters"
describe("financial formatters",()=>{it("masks account numbers",()=>expect(maskAccountNumber("0192837465")).toBe("**** 7465"));it("clamps percentages",()=>expect(percentage(120,100)).toBe(100))})
EOF
commit_if_changed "feat: define dashboard domain contracts and JSON fixture"
commit_if_changed "feat: add abortable API simulation and dashboard state store"
cat > /tmp/nb-pr2.md <<'EOF'
## Summary
Adds typed domain contracts, a JSON-backed asynchronous API boundary, cancellation, controllable latency, failure injection, formatting utilities, and a Zustand request lifecycle store.

## Manual simulation
- `?simulateError=true` forces a recoverable service error.
- `?delay=2500` increases latency for loading-state review.
EOF
finish_pr feat/dashboard-data-layer "feat: add dashboard API simulation and state architecture" /tmp/nb-pr2.md

################################################################################
# PR 3: Exact UI and features
################################################################################
log "PR 3/4: supplied UI implementation"
git checkout -b feat/dashboard-experience
mkdir -p src/config src/components/layout src/components/dashboard src/components/feedback
cat > src/config/navigation.ts <<'EOF'
import type { Icon } from "@phosphor-icons/react"
import { ArrowsLeftRight,CreditCard,GearSix,House } from "@phosphor-icons/react"
export interface NavigationItem{key:string;label:string;icon:Icon}
export const navigation:NavigationItem[]=[{key:"home",label:"Overview",icon:House},{key:"card",label:"Cards",icon:CreditCard},{key:"swap",label:"Transfers",icon:ArrowsLeftRight},{key:"settings",label:"Settings",icon:GearSix}]
EOF
cat > src/components/layout/Navigation.tsx <<'EOF'
import { navigation } from "../../config/navigation"
export function Navigation({activeTab,onChange,mobile=false}:{activeTab:string;onChange:(tab:string)=>void;mobile?:boolean}){return <nav className={mobile?"nb-bottom-tabs":"nb-nav"} aria-label={mobile?"Mobile navigation":"Primary navigation"}>{navigation.map(({key,label,icon:Icon})=><button key={key} type="button" className={`${mobile?"nb-tab-item":"nb-nav-item"}${activeTab===key?" active":""}`} aria-current={activeTab===key?"page":undefined} onClick={()=>onChange(key)}><Icon size={mobile?19:17} weight="regular"/>{label}</button>)}</nav>}
EOF
cat > src/components/layout/AppShell.tsx <<'EOF'
import type { ReactNode } from "react"
import { Bell } from "@phosphor-icons/react"
import { Navigation } from "./Navigation"
export function AppShell({holderName,activeTab,onTabChange,children}:{holderName?:string;activeTab:string;onTabChange:(tab:string)=>void;children:ReactNode}){const first=holderName?.split(" ")[0];return <div className="nb-root"><div className="nb-layout"><aside className="nb-sidebar"><div className="nb-logo">naira<span>bank</span></div><Navigation activeTab={activeTab} onChange={onTabChange}/></aside><main className="nb-main"><header className="nb-topbar"><div className="nb-greeting">{first?<>Welcome back, <strong>{first}</strong></>:<>&nbsp;</>}</div><button className="nb-icon-button" type="button" aria-label="Notifications"><Bell size={19}/><span className="nb-notification-dot"/></button></header>{children}</main></div><Navigation mobile activeTab={activeTab} onChange={onTabChange}/></div>}
EOF
cat > src/components/dashboard/Sparkline.tsx <<'EOF'
export function Sparkline({points}:{points:number[]}){const w=220,h=46,max=Math.max(...points),min=Math.min(...points);const normalized=points.map((v,i)=>[(i/Math.max(1,points.length-1))*w,h-((v-min)/(max-min||1))*h] as const);const line=normalized.map(([x,y],i)=>`${i===0?"M":"L"}${x.toFixed(1)},${y.toFixed(1)}`).join(" ");return <svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} preserveAspectRatio="none" aria-label="Seven-day account trend"><path d={`${line} L${w},${h} L0,${h} Z`} fill="rgba(185,139,46,.18)"/><path d={line} fill="none" stroke="#D8B45C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>}
EOF
cat > src/components/dashboard/BalanceHero.tsx <<'EOF'
import { Eye,EyeSlash } from "@phosphor-icons/react"
import type { Account } from "../../domain/dashboard"
import { formatNaira,maskAccountNumber } from "../../utils/formatters"
import { Sparkline } from "./Sparkline"
export function BalanceHero({account,trend,visible,onToggle}:{account:Account;trend:number[];visible:boolean;onToggle:()=>void}){return <section className="nb-hero" aria-labelledby="balance-title"><div className="nb-hero-texture"/><div className="nb-hero-row"><div><p id="balance-title" className="nb-hero-label">Available balance</p><div className="nb-balance">{visible?formatNaira(account.balance,2):"₦ ••••••••"}</div></div><button className="nb-toggle" type="button" onClick={onToggle}>{visible?<EyeSlash size={15}/>:<Eye size={15}/>} {visible?"Hide balance":"Show balance"}</button></div><div className="nb-hero-foot"><div className="nb-hero-meta"><span>{account.holderName} · {maskAccountNumber(account.accountNumber)}</span><span>7-day trend <b>+5.2%</b></span></div><div className="nb-spark"><Sparkline points={trend}/></div></div></section>}
EOF
cat > src/components/dashboard/QuickActions.tsx <<'EOF'
import { HandCoins,PaperPlaneTilt,Plus,Receipt } from "@phosphor-icons/react"
const actions=[{label:"Send",icon:PaperPlaneTilt},{label:"Request",icon:HandCoins},{label:"Top Up",icon:Plus},{label:"Bills",icon:Receipt}]
export function QuickActions({onAction}:{onAction:(action:string)=>void}){return <section className="nb-actions" aria-label="Quick actions">{actions.map(({label,icon:Icon})=><button key={label} type="button" className="nb-action" onClick={()=>onAction(label)}><span className="nb-action-icon"><Icon size={17}/></span><span>{label}</span></button>)}</section>}
EOF
cat > src/components/dashboard/TransactionList.tsx <<'EOF'
import type { Icon } from "@phosphor-icons/react"
import { ArrowsLeftRight,Car,ForkKnife,Lightning,ShoppingBag,Wallet } from "@phosphor-icons/react"
import type { Transaction,TransactionCategory } from "../../domain/dashboard"
import { formatNaira,formatTransactionDate } from "../../utils/formatters"
const icons:Record<TransactionCategory,Icon>={Shopping:ShoppingBag,Transport:Car,Bills:Lightning,Transfers:ArrowsLeftRight,Food:ForkKnife,Income:Wallet}
export function TransactionList({transactions}:{transactions:Transaction[]}){return <section className="nb-panel" aria-labelledby="transactions-title"><h2 id="transactions-title" className="nb-panel-title">Recent transactions</h2>{transactions.map((tx)=>{const TxIcon=icons[tx.category],credit=tx.kind==="credit";return <article key={tx.id} className="nb-tx-row"><div className="nb-tx-left"><div className="nb-tx-icon"><TxIcon size={16}/></div><div><div className="nb-tx-name">{tx.merchant}</div><div className="nb-tx-sub">{tx.category} · {formatTransactionDate(tx.date)}</div></div></div><span className={`nb-tx-amt${credit?" credit":""}`}>{credit?"+":"-"}{formatNaira(tx.amount)}</span></article>})}</section>}
EOF
cat > src/components/dashboard/SpendingChart.tsx <<'EOF'
import { Cell,Pie,PieChart,ResponsiveContainer,Tooltip } from "recharts"
import type { SpendingCategory } from "../../domain/dashboard"
import { formatNaira } from "../../utils/formatters"
export function SpendingChart({categories}:{categories:SpendingCategory[]}){const total=categories.reduce((sum,item)=>sum+item.value,0);return <section className="nb-panel"><h2 className="nb-panel-title">Spending breakdown</h2><div className="nb-chart-layout"><div className="nb-chart"><ResponsiveContainer width="100%" height="100%"><PieChart><Pie data={categories} dataKey="value" nameKey="name" innerRadius={36} outerRadius={52} paddingAngle={3} stroke="none">{categories.map((item)=><Cell key={item.name} fill={item.color}/>)}</Pie><Tooltip formatter={(value)=>formatNaira(Number(value))}/></PieChart></ResponsiveContainer></div><div className="nb-legend">{categories.map((item)=><div key={item.name}><span><i style={{background:item.color}}/>{item.name}</span><span>{Math.round((item.value/total)*100)}%</span></div>)}</div></div></section>}
EOF
cat > src/components/dashboard/TransferLimits.tsx <<'EOF'
import type { Account } from "../../domain/dashboard"
import { formatNaira,percentage } from "../../utils/formatters"
function Limit({label,used,limit}:{label:string;used:number;limit:number}){return <div className="nb-limit"><div className="nb-limit-row"><span>{label}</span><span>{formatNaira(used)} / {formatNaira(limit)}</span></div><div className="nb-limit-track" role="progressbar" aria-label={`${label} transfer limit used`} aria-valuenow={Math.round(percentage(used,limit))} aria-valuemin={0} aria-valuemax={100}><div className="nb-limit-fill" style={{width:`${percentage(used,limit)}%`}}/></div></div>}
export function TransferLimits({account}:{account:Account}){return <section className="nb-panel"><h2 className="nb-panel-title">Transfer limits</h2><Limit label="Daily" used={account.dailyUsed} limit={account.dailyLimit}/><Limit label="Monthly" used={account.monthlyUsed} limit={account.monthlyLimit}/></section>}
EOF
cat > src/components/feedback/ErrorState.tsx <<'EOF'
import { ArrowClockwise,WarningCircle } from "@phosphor-icons/react"
export function ErrorState({message,onRetry}:{message:string;onRetry:()=>void}){return <section className="nb-error" role="alert"><WarningCircle size={26}/><div><strong>Account data unavailable</strong><p>{message}</p></div><button type="button" onClick={onRetry}><ArrowClockwise size={17}/> Retry</button></section>}
EOF
cat > src/components/feedback/Toast.tsx <<'EOF'
export function Toast({message}:{message:string}){return <div className="nb-toast" role="status">{message}</div>}
EOF
cat > src/app/App.tsx <<'EOF'
import { useState } from "react"
import { AppShell } from "../components/layout/AppShell"
import { BalanceHero } from "../components/dashboard/BalanceHero"
import { QuickActions } from "../components/dashboard/QuickActions"
import { SpendingChart } from "../components/dashboard/SpendingChart"
import { TransactionList } from "../components/dashboard/TransactionList"
import { TransferLimits } from "../components/dashboard/TransferLimits"
import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
import { ErrorState } from "../components/feedback/ErrorState"
import { Toast } from "../components/feedback/Toast"
import { useDashboard } from "../hooks/useDashboard"
import { useDashboardStore } from "../store/useDashboardStore"
export function App(){const{status,data,error,retry}=useDashboard();const visible=useDashboardStore((s)=>s.balanceVisible);const toggle=useDashboardStore((s)=>s.toggleBalance);const tab=useDashboardStore((s)=>s.activeTab);const setTab=useDashboardStore((s)=>s.setActiveTab);const[toast,setToast]=useState("");const action=(label:string)=>{setToast(`${label} is simulated in this frontend demo.`);window.setTimeout(()=>setToast(""),2200)};return <AppShell holderName={data?.account.holderName} activeTab={tab} onTabChange={setTab}>{status==="loading"||status==="idle"?<DashboardSkeleton/>:status==="error"?<ErrorState message={error??"Unexpected error"} onRetry={()=>void retry()}/>:data?<><BalanceHero account={data.account} trend={data.trend} visible={visible} onToggle={toggle}/><QuickActions onAction={action}/><div className="nb-grid"><TransactionList transactions={data.transactions}/><div className="nb-side-stack"><SpendingChart categories={data.categories}/><TransferLimits account={data.account}/></div></div></>:null}{toast&&<Toast message={toast}/>}</AppShell>}
EOF
cat > src/styles/global.css <<'EOF'
:root{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:#10150f;background:#f4f5f1;font-synthesis:none;text-rendering:optimizeLegibility}*{box-sizing:border-box}html{min-width:320px;background:#f4f5f1}body{margin:0;min-width:320px;min-height:100vh}button{font:inherit;cursor:pointer}.nb-root{--bg:#f4f5f1;--surface:#fff;--border:#e2e4de;--text:#10150f;--text-dim:#676f63;--accent:#1f8a5f;--accent-soft:#e7f2eb;--gold:#b98b2e;--hero:#0e2a20;--hero-2:#143a2c;--danger:#b4442c;min-height:100vh;background:var(--bg);color:var(--text)}.nb-root button:focus-visible{outline:2px solid var(--accent);outline-offset:2px}.nb-layout{display:flex;min-height:100vh}.nb-sidebar{width:232px;flex-shrink:0;background:var(--hero);color:#edefea;padding:24px 16px;display:flex;flex-direction:column;gap:28px}.nb-logo{font-size:18px;font-weight:800;letter-spacing:-.01em;padding:0 8px}.nb-logo span{color:var(--gold)}.nb-nav{display:flex;flex-direction:column;gap:2px}.nb-nav-item{display:flex;align-items:center;gap:12px;width:100%;padding:10px 12px;border:0;border-radius:10px;background:transparent;color:#b9c4b7;font-size:13.5px;text-align:left}.nb-nav-item.active{background:rgba(255,255,255,.08);color:#fff}.nb-main{flex:1;min-width:0;max-width:980px;padding:28px 32px 100px}.nb-topbar{display:flex;align-items:center;justify-content:space-between;margin-bottom:22px}.nb-greeting{font-size:15px;color:var(--text-dim)}.nb-greeting strong{color:var(--text)}.nb-icon-button{position:relative;display:grid;place-items:center;border:0;background:transparent;color:var(--text-dim)}.nb-notification-dot{position:absolute;right:-1px;top:-1px;width:6px;height:6px;border-radius:50%;background:var(--danger)}.nb-hero{position:relative;overflow:hidden;border-radius:20px;background:linear-gradient(155deg,var(--hero),var(--hero-2));color:#edefea;padding:26px 26px 22px;margin-bottom:20px}.nb-hero-texture{position:absolute;inset:0;opacity:.5;background-image:repeating-linear-gradient(115deg,rgba(255,255,255,.035) 0,rgba(255,255,255,.035) 1px,transparent 1px,transparent 7px)}.nb-hero-row,.nb-hero-foot{position:relative;display:flex;justify-content:space-between;gap:20px;flex-wrap:wrap}.nb-hero-row{align-items:flex-start}.nb-hero-foot{align-items:flex-end;margin-top:18px}.nb-hero-label{margin:0 0 8px;color:#9fb0a5;font-size:12px;letter-spacing:.06em;text-transform:uppercase}.nb-balance{font-size:40px;font-weight:800;letter-spacing:-.02em;font-variant-numeric:tabular-nums;line-height:1.05}.nb-toggle{display:flex;align-items:center;gap:7px;border:1px solid rgba(255,255,255,.14);border-radius:999px;background:rgba(255,255,255,.08);color:#edefea;padding:8px 14px;font-size:12.5px}.nb-hero-meta{display:flex;flex-direction:column;gap:3px;color:#9fb0a5;font-size:12.5px}.nb-hero-meta b{color:#edefea}.nb-spark{width:190px}.nb-actions{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:20px}.nb-action{display:flex;flex-direction:column;align-items:center;gap:8px;padding:14px 6px;border:1px solid var(--border);border-radius:14px;background:var(--surface);color:var(--text)}.nb-action:hover{border-color:var(--accent);background:var(--accent-soft)}.nb-action-icon{display:flex;align-items:center;justify-content:center;width:34px;height:34px;border-radius:10px;background:var(--accent-soft);color:var(--accent)}.nb-action span:last-child{color:var(--text-dim);font-size:11.5px}.nb-grid{display:grid;grid-template-columns:1.3fr 1fr;gap:20px;align-items:start}.nb-side-stack{display:flex;flex-direction:column;gap:20px}.nb-panel{border:1px solid var(--border);border-radius:18px;background:var(--surface);padding:20px}.nb-panel-title{margin:0 0 14px;color:var(--text-dim);font-size:12.5px;font-weight:700;letter-spacing:.05em;text-transform:uppercase}.nb-tx-row{display:flex;align-items:center;justify-content:space-between;padding:11px 0;border-bottom:1px solid var(--border)}.nb-tx-row:last-child{border-bottom:0;padding-bottom:0}.nb-tx-left{display:flex;align-items:center;gap:12px;min-width:0}.nb-tx-icon{display:flex;flex-shrink:0;align-items:center;justify-content:center;width:36px;height:36px;border-radius:10px;background:var(--bg);color:var(--text-dim)}.nb-tx-name{font-size:13.5px;font-weight:500}.nb-tx-sub{margin-top:2px;color:var(--text-dim);font-size:11.5px}.nb-tx-amt{font-size:13.5px;font-weight:700;font-variant-numeric:tabular-nums;white-space:nowrap}.nb-tx-amt.credit{color:var(--accent)}.nb-chart-layout{display:flex;align-items:center;gap:14px}.nb-chart{width:104px;height:104px;flex-shrink:0}.nb-legend{display:flex;flex:1;flex-direction:column;gap:7px}.nb-legend>div{display:flex;justify-content:space-between;font-size:12px}.nb-legend span:first-child{display:flex;align-items:center;gap:7px}.nb-legend i{display:inline-block;width:7px;height:7px;border-radius:50%}.nb-legend span:last-child{color:var(--text-dim)}.nb-limit{margin-bottom:16px}.nb-limit:last-child{margin-bottom:0}.nb-limit-row{display:flex;justify-content:space-between;margin-bottom:6px;font-size:12px}.nb-limit-row span:first-child{color:var(--text-dim)}.nb-limit-track{height:6px;overflow:hidden;border-radius:999px;background:var(--bg)}.nb-limit-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,var(--accent),var(--gold))}.nb-skel{position:relative;overflow:hidden;border-radius:16px;background:#e8e9e4}.nb-skel:after{position:absolute;inset:0;content:"";transform:translateX(-100%);background:linear-gradient(90deg,transparent,rgba(255,255,255,.75),transparent);animation:nb-shimmer 1.4s infinite}.nb-skel-hero{height:176px;margin-bottom:20px}.nb-skel-action{height:78px}.nb-skel-panel{height:260px}.nb-error{display:flex;align-items:center;gap:14px;border:1px solid #e7b8ad;border-radius:18px;background:#fff7f5;padding:20px;color:var(--danger)}.nb-error p{margin:4px 0 0;color:#75544d}.nb-error button{display:flex;align-items:center;gap:7px;margin-left:auto;border:1px solid #e7b8ad;border-radius:10px;background:#fff;padding:9px 12px;color:var(--danger)}.nb-toast{position:fixed;right:24px;bottom:24px;z-index:30;border:1px solid var(--border);border-radius:12px;background:var(--hero);color:#fff;padding:12px 16px;box-shadow:0 18px 45px rgba(14,42,32,.22)}.nb-bottom-tabs{display:none}@keyframes nb-shimmer{to{transform:translateX(100%)}}@media(prefers-reduced-motion:reduce){.nb-root *{animation:none!important;transition:none!important}}@media(max-width:1023px){.nb-sidebar{display:none}.nb-main{max-width:100%;padding:20px 20px 96px}}@media(max-width:860px){.nb-grid{grid-template-columns:1fr}.nb-hero-foot{flex-direction:column;align-items:flex-start}.nb-spark{width:100%}}@media(max-width:560px){.nb-balance{font-size:32px}.nb-main{padding:18px 16px 92px}.nb-bottom-tabs{position:fixed;right:0;bottom:0;left:0;z-index:20;display:flex;justify-content:space-around;border-top:1px solid var(--border);background:rgba(255,255,255,.96);padding:8px 6px calc(8px + env(safe-area-inset-bottom));backdrop-filter:blur(14px)}.nb-tab-item{display:flex;flex-direction:column;align-items:center;gap:3px;border:0;background:transparent;color:var(--text-dim);padding:4px 10px;font-size:10.5px}.nb-tab-item.active{color:var(--accent)}.nb-toast{right:16px;bottom:78px;left:16px}}@media(max-width:390px){.nb-hero{padding:22px 20px 19px}.nb-actions{grid-template-columns:repeat(2,1fr)}.nb-chart-layout{flex-direction:column;align-items:flex-start}.nb-chart{width:100%;height:130px}.nb-limit-row{flex-direction:column;gap:3px}.nb-tx-name{max-width:150px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}}
EOF
cat > src/app/App.test.tsx <<'EOF'
import { render,screen,waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach,describe,expect,it,vi } from "vitest"
import { App } from "./App"
const response={ok:true,json:async()=>({account:{holderName:"Amara Chukwu",accountNumber:"0192837465",balance:482350.75,dailyLimit:500000,dailyUsed:76500,monthlyLimit:5000000,monthlyUsed:1875200},trend:[40,44,42],transactions:[],categories:[]})}
beforeEach(()=>{vi.stubGlobal("fetch",vi.fn().mockResolvedValue(response));window.history.replaceState({},"","/?delay=0")})
describe("dashboard",()=>{it("loads account data",async()=>{render(<App/>);expect(await screen.findByText(/₦482,350.75/)).toBeInTheDocument()});it("provides simulated action feedback",async()=>{const user=userEvent.setup();render(<App/>);await screen.findByText(/₦482,350.75/);await user.click(screen.getByRole("button",{name:"Send"}));await waitFor(()=>expect(screen.getByRole("status")).toHaveTextContent(/simulated/i))})})
EOF
commit_if_changed "feat: implement modular dashboard feature components"
commit_if_changed "feat: reproduce supplied responsive NairaBank interface"
commit_if_changed "test: cover dashboard loading and action feedback"
cat > /tmp/nb-pr3.md <<'EOF'
## Summary
Implements the supplied NairaBank design with modular layout, navigation, balance, quick actions, transactions, spending chart, transfer limits, loading, errors, and responsive mobile behavior.
EOF
finish_pr feat/dashboard-experience "feat: implement responsive NairaBank dashboard experience" /tmp/nb-pr3.md

################################################################################
# PR 4: Docs, hardening, Vercel
################################################################################
log "PR 4/4: hardening and documentation"
git checkout -b chore/quality-and-documentation
cat > README.md <<'EOF'
# NairaBank

NairaBank is a responsive Nigerian retail-banking dashboard simulation built with React, TypeScript, Vite, Zustand, Recharts, and Phosphor Icons.

It is intentionally frontend-only. It demonstrates component architecture, asynchronous service behavior, domain modelling, loading and failure states, responsive financial data presentation, accessibility, tests, and production build discipline without presenting itself as a licensed bank.

## Features

- Available balance with privacy toggle
- Masked Nigerian account number
- Seven-day balance trend
- Quick action simulations
- Recent transaction history
- Spending category chart
- Daily and monthly transfer limits
- Desktop sidebar and mobile bottom navigation
- Shimmer loading and retryable errors

## Commands

    npm install
    npm run dev
    npm run lint
    npm run typecheck
    npm run test
    npm run build

## Simulation controls

- `?simulateError=true` forces a recoverable request failure.
- `?delay=2500` extends artificial latency.

## Vercel

Build command: `npm run build`
Output directory: `dist`

## Disclaimer

This is a portfolio demonstration. It does not authenticate users, store customer data, initiate transfers, or connect to financial infrastructure.
EOF
cat > docs/ARCHITECTURE.md <<'EOF'
# Architecture

## Objective

Behave like a small production frontend while remaining honest about frontend-only scope. Remote-like state, domain contracts, transport mechanics, shared UI state, feature presentation, and deterministic utilities are separated so a real backend can replace the fixture without restructuring the interface.

## Module boundaries

- `domain`: stable account, transaction, and spending contracts
- `services`: HTTP behavior, latency, cancellation, and failure injection
- `store`: request lifecycle and small shared UI state
- `hooks`: React lifecycle integration
- `components/layout`: shell and responsive navigation
- `components/dashboard`: financial presentation
- `components/feedback`: loading, error, and transient messages
- `utils`: deterministic formatting and progress calculations
- `public/dashboard.json`: replaceable development API fixture

## Data flow

1. `useDashboard` requests data when the store is idle.
2. The store cancels any prior request and enters loading.
3. `dashboardService` applies controllable latency and calls `httpClient`.
4. Success is committed atomically, preventing partial dashboard renders.
5. Failures become explicit recoverable state.
6. Components consume typed values without transport knowledge.

## JSON fixture decision

Fetching JSON preserves a genuine asynchronous browser boundary. Importing a constant would hide request behavior and couple the dataset to the JavaScript bundle.

## Cancellation

A new request aborts the previous one, protecting the store from stale responses during retries and React Strict Mode remount behavior.
EOF
cat > docs/ENGINEERING_DECISIONS.md <<'EOF'
# Engineering decisions and trade-offs

## React and TypeScript

React suits independently evolving dashboard features. Strict TypeScript catches unsafe integration assumptions. The additional tooling is justified for a portfolio project intended to demonstrate maintainability.

## Vite instead of Next.js

The product has one static dashboard, no server rendering requirement, and no backend routes. A full-stack framework would add deployment and routing surface without product value.

## Zustand instead of Redux or Context

Shared state is limited to request lifecycle, active navigation, and balance privacy. Redux would add ceremony. A monolithic context would work but offers less precise subscriptions. Zustand is small and reversible.

## Recharts

The supplied design includes one donut chart. Recharts provides responsive SVG behavior, tooltips, and a mature React API. Handwritten SVG would reduce dependency weight but increase geometry and testing cost.

## Phosphor Icons

Phosphor offers mature typed React exports and consistent outline iconography that matches the supplied restrained banking design.

## Service layer

Components never call `fetch` directly. HTTP failures, cancellation, latency, and fixture location stay behind services. The indirection is small and materially lowers migration cost.

## No authentication

Fake authentication would imply security that does not exist. A production banking product would require server-side authorization, secure sessions, step-up verification, device risk controls, and audit trails.

## No router

The requested scope is one dashboard. Navigation state demonstrates layout behavior without pretending multiple screens exist.
EOF
cat > docs/FAILURE_MODES.md <<'EOF'
# Failure modes and recovery

## Dashboard request failure

The store enters `error`, retains a human-readable message, and exposes retry. It never invents partial balances.

## Superseded request

The previous AbortController is cancelled. Abort errors are ignored because they are expected lifecycle behavior.

## Runtime JSON drift

TypeScript protects compile-time consumers but not remote payloads. A real API should add runtime schema validation with Zod, Valibot, or generated contracts.

## Invalid limits

Percentage calculations guard against zero and negative limits and clamp output to zero through one hundred.

## Slow network

Skeletons preserve final geometry and reduce layout shift. The delay query parameter supports manual inspection.

## Chart failure

The chart is supplementary. Critical transaction and limit values remain available as text.
EOF
cat > docs/SECURITY_AND_COMPLIANCE.md <<'EOF'
# Security and compliance boundary

NairaBank is a frontend simulation, not a regulated financial system.

A production implementation would require:

- authenticated, authorized server APIs
- encrypted transport and secure session handling
- server-side balance and limit enforcement
- transaction idempotency and replay protection
- step-up verification for sensitive actions
- fraud, velocity, and beneficiary controls
- privacy-safe telemetry and immutable audit logs
- PCI DSS scoping where card data is involved
- NDPR and applicable CBN requirements
- formal threat modelling and penetration testing

No decision made in this browser should be trusted by a real financial backend.
EOF
cat > docs/ACCESSIBILITY.md <<'EOF'
# Accessibility

Implemented considerations:

- semantic navigation, sections, headings, status, and alert roles
- keyboard focus indicators
- button labels for icon-only controls
- progressbar semantics for transfer limits
- reduced-motion support
- touch-friendly mobile navigation
- text alternatives around financial graphics
- responsive layouts without required horizontal scrolling

A production release should complete keyboard-only, screen-reader, zoom, contrast, and WCAG 2.2 AA testing with real users.
EOF
cat > docs/TESTING.md <<'EOF'
# Testing strategy

## Automated

- formatter and percentage unit tests
- initial loading-state test
- successful account-load integration test
- simulated action feedback test
- strict type checking
- ESLint with zero warnings
- production Vite build

## Manual

- desktop sidebar and mobile bottom navigation
- balance hide/show interaction
- `?delay=2500` loading behavior
- `?simulateError=true` retry behavior
- responsive widths at 320, 390, 560, 860, 1024, and wide desktop
- reduced-motion operating-system preference
- Vercel production deployment
EOF
cat > vercel.json <<'EOF'
{
  "framework": "vite",
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "cleanUrls": true,
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" }
      ]
    }
  ]
}
EOF
cat > .env.example <<'EOF'
VITE_API_BASE_URL=https://api.example.invalid
EOF
commit_if_changed "docs: document architecture decisions and failure modes"
commit_if_changed "docs: define security accessibility and testing boundaries"
commit_if_changed "chore: configure Vercel production deployment"
cat > /tmp/nb-pr4.md <<'EOF'
## Summary
Adds detailed architecture, decision, failure-mode, security, accessibility, testing, and deployment documentation. Configures Vercel headers and validates the final production build.
EOF
finish_pr chore/quality-and-documentation "chore: harden NairaBank and document engineering decisions" /tmp/nb-pr4.md

log "Final validation"
validate
printf '\nNairaBank is complete on %s.\n' "$BASE_BRANCH"
printf 'Run: npm run dev\n'
printf 'Deploy: npx vercel\n'
if [[ "$SKIP_GITHUB" != "1" ]]; then gh pr list --state merged --limit 4 --json number,title,url --template '{{range .}}{{printf "#%v %s\n%s\n\n" .number .title .url}}{{end}}'; fi
