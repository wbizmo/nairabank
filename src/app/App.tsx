import { DashboardSkeleton } from "../components/common/DashboardSkeleton"
export function App(){
  return <div className="nb-root"><div className="nb-layout"><aside className="nb-sidebar"><div className="nb-logo">naira<span>bank</span></div></aside><main className="nb-main"><div className="nb-topbar"><div className="nb-greeting">Loading your account</div></div><DashboardSkeleton /></main></div></div>
}
