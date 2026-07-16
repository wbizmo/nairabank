import { Header } from "./components/Header"
import { DashboardSkeleton } from "./components/Skeleton"

export default function App() {
  return (
    <div className="app-shell">
      <Header />
      <DashboardSkeleton />
    </div>
  )
}
