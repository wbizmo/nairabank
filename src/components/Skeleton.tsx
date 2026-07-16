export function DashboardSkeleton() {
  return (
    <div className="stack">
      <div className="grid">
        <div className="skeleton card" style={{ height: 210 }} />
        <div className="stack">
          <div className="skeleton card" style={{ height: 96 }} />
          <div className="skeleton card" style={{ height: 96 }} />
        </div>
      </div>
      <div className="grid-inner">
        <div className="skeleton card" style={{ height: 260 }} />
        <div className="skeleton card" style={{ height: 260 }} />
      </div>
    </div>
  )
}
