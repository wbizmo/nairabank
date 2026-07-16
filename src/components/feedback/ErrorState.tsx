import { ArrowClockwise,WarningCircle } from "@phosphor-icons/react"
export function ErrorState({message,onRetry}:{message:string;onRetry:()=>void}){return <section className="nb-error" role="alert"><WarningCircle size={26}/><div><strong>Account data unavailable</strong><p>{message}</p></div><button type="button" onClick={onRetry}><ArrowClockwise size={17}/> Retry</button></section>}
