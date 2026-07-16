import type { Icon } from "@phosphor-icons/react"
import { ArrowsLeftRight,CreditCard,GearSix,House } from "@phosphor-icons/react"
export interface NavigationItem{key:string;label:string;icon:Icon}
export const navigation:NavigationItem[]=[{key:"home",label:"Overview",icon:House},{key:"card",label:"Cards",icon:CreditCard},{key:"swap",label:"Transfers",icon:ArrowsLeftRight},{key:"settings",label:"Settings",icon:GearSix}]
