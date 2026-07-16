import { HandCoins,PaperPlaneTilt,Plus,Receipt } from "@phosphor-icons/react"
const actions=[{label:"Send",icon:PaperPlaneTilt},{label:"Request",icon:HandCoins},{label:"Top Up",icon:Plus},{label:"Bills",icon:Receipt}]
export function QuickActions({onAction}:{onAction:(action:string)=>void}){return <section className="nb-actions" aria-label="Quick actions">{actions.map(({label,icon:Icon})=><button key={label} type="button" className="nb-action" onClick={()=>onAction(label)}><span className="nb-action-icon"><Icon size={17}/></span><span>{label}</span></button>)}</section>}
