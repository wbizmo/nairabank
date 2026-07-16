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
