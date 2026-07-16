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
