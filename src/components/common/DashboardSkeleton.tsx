export function DashboardSkeleton() {
  return <div aria-label="Loading dashboard" aria-busy="true">
    <div className="nb-skel nb-skel-hero" />
    <div className="nb-actions">{[0,1,2,3].map((item)=><div key={item} className="nb-skel nb-skel-action" />)}</div>
    <div className="nb-grid"><div className="nb-skel nb-skel-panel" /><div className="nb-skel nb-skel-panel" /></div>
  </div>
}
