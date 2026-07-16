export function formatNaira(value:number,maximumFractionDigits=0){return new Intl.NumberFormat("en-NG",{style:"currency",currency:"NGN",maximumFractionDigits}).format(value)}
export function formatTransactionDate(value:string){return new Intl.DateTimeFormat("en-NG",{day:"numeric",month:"short"}).format(new Date(value))}
export function maskAccountNumber(value:string){return `**** ${value.slice(-4)}`}
export function percentage(used:number,limit:number){if(limit<=0)return 0;return Math.min(100,Math.max(0,(used/limit)*100))}
